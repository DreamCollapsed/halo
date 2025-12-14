#include <gtest/gtest.h>

#include <duckdb.hpp>
#include <duckdb/main/client_context.hpp>
#include <duckdb/optimizer/optimizer.hpp>
#include <duckdb/parser/parser.hpp>
#include <duckdb/planner/planner.hpp>

namespace halo::test {

class DuckDBIntegrationTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // Setup code if needed
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

}  // namespace halo::test
