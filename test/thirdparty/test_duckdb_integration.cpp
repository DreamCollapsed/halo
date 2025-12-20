#include <gtest/gtest.h>

// Provide hash specialization for __int128 before including Folly headers
// This is needed because std::hash<__int128> is not defined in the standard
// library
#if defined(__linux__) && defined(__SIZEOF_INT128__)
namespace std {
template <>
struct hash<__int128> {
  size_t operator()(__int128 value) const noexcept {
    // Combine high and low 64 bits using a simple hash function
    uint64_t low = static_cast<uint64_t>(value);
    uint64_t high = static_cast<uint64_t>(value >> 64);
    // Use FNV-1a style mixing
    return hash<uint64_t>{}(low) ^ (hash<uint64_t>{}(high) << 1);
  }
};

template <>
struct hash<unsigned __int128> {
  size_t operator()(unsigned __int128 value) const noexcept {
    uint64_t low = static_cast<uint64_t>(value);
    uint64_t high = static_cast<uint64_t>(value >> 64);
    return hash<uint64_t>{}(low) ^ (hash<uint64_t>{}(high) << 1);
  }
};
}  // namespace std
#endif

#include <velox/common/memory/Memory.h>
#include <velox/core/Expressions.h>
#include <velox/core/PlanNode.h>
#include <velox/parse/PlanNodeIdGenerator.h>
#include <velox/type/Type.h>
#include <velox/type/Variant.h>
#include <velox/vector/FlatVector.h>

#include <duckdb.hpp>
#include <duckdb/main/client_context.hpp>
#include <duckdb/optimizer/optimizer.hpp>
#include <duckdb/parser/parser.hpp>
#include <duckdb/planner/expression/bound_comparison_expression.hpp>
#include <duckdb/planner/expression/bound_constant_expression.hpp>
#include <duckdb/planner/expression/bound_reference_expression.hpp>
#include <duckdb/planner/operator/logical_dummy_scan.hpp>
#include <duckdb/planner/operator/logical_filter.hpp>
#include <duckdb/planner/operator/logical_get.hpp>
#include <duckdb/planner/operator/logical_projection.hpp>
#include <duckdb/planner/planner.hpp>
#include <mutex>

namespace halo::test {

class DuckDBIntegrationTest : public ::testing::Test {
 protected:
  void SetUp() override {
    static std::once_flag once;
    std::call_once(
        once, []() { facebook::velox::memory::MemoryManager::initialize({}); });
  }

  void TearDown() override {
    // Cleanup code if needed
  }
};

TEST_F(DuckDBIntegrationTest, BasicQuery) {
  duckdb::DuckDB db(nullptr);
  duckdb::Connection con(db);

  auto result = con.Query("SELECT 42");
  ASSERT_FALSE(result->HasError()) << result->GetError();

  auto chunk = result->Fetch();
  ASSERT_TRUE(chunk);
  ASSERT_EQ(chunk->size(), 1);

  auto value = chunk->GetValue(0, 0);
  ASSERT_EQ(value.GetValue<int32_t>(), 42);
}

TEST_F(DuckDBIntegrationTest, CreateTableAndInsert) {
  duckdb::DuckDB db(nullptr);
  duckdb::Connection con(db);

  ASSERT_FALSE(
      con.Query("CREATE TABLE integers (i INTEGER, j INTEGER)")->HasError());
  ASSERT_FALSE(
      con.Query("INSERT INTO integers VALUES (3, 4), (5, 6), (7, NULL)")
          ->HasError());

  auto result = con.Query("SELECT count(*) FROM integers");
  ASSERT_FALSE(result->HasError());

  auto chunk = result->Fetch();
  ASSERT_EQ(chunk->GetValue(0, 0).GetValue<int64_t>(), 3);
}

TEST_F(DuckDBIntegrationTest, AccessParserAndOptimizer) {
  duckdb::DuckDB db(nullptr);
  duckdb::Connection con(db);

  std::string sql = "SELECT 42 AS a, 'hello' AS b WHERE a > 10";

  // 1. Parser: SQL -> AST (Statement)
  duckdb::Parser parser;
  parser.ParseQuery(sql);
  ASSERT_FALSE(parser.statements.empty());
  ASSERT_EQ(parser.statements.size(), 1);

  auto& statement = *parser.statements[0];
  ASSERT_EQ(statement.type, duckdb::StatementType::SELECT_STATEMENT);

  // 2. Planner: AST -> Logical Plan (Unoptimized)
  // We need to access the ClientContext from the connection
  duckdb::Planner planner(*con.context);
  planner.CreatePlan(statement.Copy());
  ASSERT_TRUE(planner.plan);

  // 3. Optimizer: Logical Plan -> Optimized Logical Plan
  duckdb::Optimizer optimizer(*planner.binder, *con.context);
  auto optimized_plan = optimizer.Optimize(std::move(planner.plan));

  ASSERT_TRUE(optimized_plan);

  // Verify we can get the string representation
  std::string plan_str = optimized_plan->ToString();
  ASSERT_FALSE(plan_str.empty());

  // Optional: Print for manual verification
  std::cout << "Optimized Plan:\n" << plan_str << '\n';
}

TEST_F(DuckDBIntegrationTest, DuckDBOptimizerToVelox) {
  duckdb::DuckDB db(nullptr);
  duckdb::Connection con(db);

  // Simple query to test translation
  std::string sql = "SELECT 13 AS a";

  con.BeginTransaction();
  auto plan = con.ExtractPlan(sql);
  con.Commit();

  ASSERT_TRUE(plan);
  auto* optimized_plan = plan.get();
  ASSERT_TRUE(optimized_plan);

  std::cout << "DuckDB Plan:\n" << optimized_plan->ToString() << "\n";

  // --- Velox Setup ---
  auto pool = facebook::velox::memory::memoryManager()->addLeafPool();
  auto planNodeIdGenerator =
      std::make_shared<facebook::velox::core::PlanNodeIdGenerator>();

  // Helper to convert DuckDB Expression to Velox Expression
  std::function<facebook::velox::core::TypedExprPtr(
      const duckdb::Expression&, const facebook::velox::RowTypePtr&)>
      toVeloxExpr;

  toVeloxExpr = [&](const duckdb::Expression& expr,
                    const facebook::velox::RowTypePtr& inputType)
      -> facebook::velox::core::TypedExprPtr {
    // Safety check
    if (!inputType) {
      throw std::runtime_error(
          "Input type is null during expression translation");
    }

    // 1. Handle Constants
    if (expr.type == duckdb::ExpressionType::VALUE_CONSTANT) {
      const auto& constExpr =
          dynamic_cast<const duckdb::BoundConstantExpression&>(expr);
      const auto& value = constExpr.value;

      switch (value.type().id()) {
        case duckdb::LogicalTypeId::INTEGER:
          return std::make_shared<facebook::velox::core::ConstantTypedExpr>(
              facebook::velox::INTEGER(),
              facebook::velox::variant(value.GetValue<int32_t>()));
        case duckdb::LogicalTypeId::BIGINT:
          return std::make_shared<facebook::velox::core::ConstantTypedExpr>(
              facebook::velox::BIGINT(),
              facebook::velox::variant(value.GetValue<int64_t>()));
        case duckdb::LogicalTypeId::VARCHAR:
          return std::make_shared<facebook::velox::core::ConstantTypedExpr>(
              facebook::velox::VARCHAR(),
              facebook::velox::variant(value.GetValue<std::string>()));
        case duckdb::LogicalTypeId::BOOLEAN:
          return std::make_shared<facebook::velox::core::ConstantTypedExpr>(
              facebook::velox::BOOLEAN(),
              facebook::velox::variant(value.GetValue<bool>()));
        case duckdb::LogicalTypeId::DOUBLE:
          return std::make_shared<facebook::velox::core::ConstantTypedExpr>(
              facebook::velox::DOUBLE(),
              facebook::velox::variant(value.GetValue<double>()));
        default:
          throw std::runtime_error("Unsupported constant type: " +
                                   value.type().ToString());
      }
    }

    // 2. Handle Column References
    if (expr.type == duckdb::ExpressionType::BOUND_COLUMN_REF) {
      const auto& colRef =
          dynamic_cast<const duckdb::BoundReferenceExpression&>(expr);
      auto columnIndex = colRef.index;

      if (columnIndex >= inputType->size()) {
        throw std::runtime_error("Column index out of bounds: " +
                                 std::to_string(columnIndex));
      }

      return std::make_shared<facebook::velox::core::FieldAccessTypedExpr>(
          inputType->childAt(columnIndex), inputType->nameOf(columnIndex));
    }

    // 3. Handle Casts (Implicit or Explicit)
    if (expr.type == duckdb::ExpressionType::OPERATOR_CAST) {
      // Recursively translate the child expression
      // Note: In a real implementation, we would wrap this in a CastTypedExpr.
      // For now, we just pass through or throw if types don't match,
      // but this is where you'd add Cast logic.
      // auto childExpr = toVeloxExpr(*expr.children[0], inputType);
      // return
      // std::make_shared<facebook::velox::core::CastTypedExpr>(targetType,
      // childExpr, false);
    }

    throw std::runtime_error("Unsupported expression type: " +
                             duckdb::ExpressionTypeToString(expr.type));
  };

  // Recursive function to traverse DuckDB plan and build Velox plan
  std::function<facebook::velox::core::PlanNodePtr(
      const duckdb::LogicalOperator*)>
      toVeloxPlan;

  toVeloxPlan = [&](const duckdb::LogicalOperator* op)
      -> facebook::velox::core::PlanNodePtr {
    if (!op) {
      return nullptr;
    }

    // 1. Translate Children first
    std::vector<facebook::velox::core::PlanNodePtr> veloxChildren;
    for (const auto& child : op->children) {
      veloxChildren.push_back(toVeloxPlan(child.get()));
    }

    auto id = planNodeIdGenerator->next();

    // 2. Translate Current Node
    switch (op->type) {
      case duckdb::LogicalOperatorType::LOGICAL_PROJECTION: {
        // DuckDB Projection -> Velox ProjectNode

        const auto& proj = dynamic_cast<const duckdb::LogicalProjection&>(*op);
        std::vector<std::string> names;
        std::vector<facebook::velox::core::TypedExprPtr> exprs;

        // We need the input type from the child to bind expressions
        facebook::velox::RowTypePtr inputType;
        if (!veloxChildren.empty()) {
          inputType = veloxChildren[0]->outputType();
        }

        for (size_t i = 0; i < proj.expressions.size(); ++i) {
          auto& expr = *proj.expressions[i];
          std::string name = expr.alias;

          if (name.empty() &&
              expr.type == duckdb::ExpressionType::BOUND_COLUMN_REF) {
            const auto& colRef =
                dynamic_cast<const duckdb::BoundReferenceExpression&>(expr);
            if (colRef.index < inputType->size()) {
              name = inputType->nameOf(colRef.index);
            }
          }

          if (name.empty()) {
            name = "c" + std::to_string(i);
          }

          names.push_back(name);
          exprs.push_back(toVeloxExpr(expr, inputType));
        }

        return std::make_shared<facebook::velox::core::ProjectNode>(
            id, std::move(names), std::move(exprs),
            veloxChildren[0]  // Project must have a source
        );
      }

      case duckdb::LogicalOperatorType::LOGICAL_DUMMY_SCAN: {
        // DuckDB Dummy Scan -> Velox ValuesNode (1 row, 0 columns)
        return std::make_shared<facebook::velox::core::ValuesNode>(
            id, std::vector<facebook::velox::RowVectorPtr>{
                    std::make_shared<facebook::velox::RowVector>(
                        pool.get(), facebook::velox::ROW({}, {}), nullptr,
                        1,  // 1 row
                        std::vector<facebook::velox::VectorPtr>{})});
      }

      default:
        throw std::runtime_error("Unsupported operator: " +
                                 duckdb::LogicalOperatorToString(op->type));
    }
  };

  try {
    auto veloxPlan = toVeloxPlan(optimized_plan);
    ASSERT_TRUE(veloxPlan);
    std::cout << "Velox Plan:\n" << veloxPlan->toString(true, true) << "\n";

    // Verify Plan Structure
    // Expected: ProjectNode -> ValuesNode
    auto projectNode =
        std::dynamic_pointer_cast<const facebook::velox::core::ProjectNode>(
            veloxPlan);
    ASSERT_TRUE(projectNode) << "Root node should be a ProjectNode";

    // Verify ProjectNode Output
    ASSERT_EQ(projectNode->names().size(), 1);
    ASSERT_EQ(projectNode->names()[0], "a");
    ASSERT_EQ(projectNode->outputType()->childAt(0)->kind(),
              facebook::velox::TypeKind::INTEGER);

    // Verify the constant value is 1
    auto projections = projectNode->projections();
    ASSERT_EQ(projections.size(), 1);
    auto constantExpr = std::dynamic_pointer_cast<
        const facebook::velox::core::ConstantTypedExpr>(projections[0]);
    ASSERT_TRUE(constantExpr) << "Expression should be a constant";
    ASSERT_EQ(constantExpr->value().value<int32_t>(), 13);

    // Verify Source
    auto sourceNode = projectNode->sources()[0];
    auto valuesNode =
        std::dynamic_pointer_cast<const facebook::velox::core::ValuesNode>(
            sourceNode);
    ASSERT_TRUE(valuesNode) << "Source node should be a ValuesNode";

    // Verify ValuesNode (Dummy Scan)
    // Should have 1 row and 0 columns
    const auto& values = valuesNode->values();
    ASSERT_EQ(values.size(), 1);
    ASSERT_EQ(values[0]->size(), 1);          // 1 row
    ASSERT_EQ(values[0]->childrenSize(), 0);  // 0 columns

  } catch (const std::exception& e) {
    std::cout << "Translation failed: " << e.what() << "\n";
    FAIL() << "Translation failed: " << e.what();
  }
}

}  // namespace halo::test
