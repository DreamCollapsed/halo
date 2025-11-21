// Simplified pipeline tests: only construct plan graph and assert structure.
// Rewritten to use a single test fixture with one-time memory setup without
// touching AsyncDataCache. We deliberately avoid including MemoryPool.h (which
// pulls AsyncDataCache.h and triggers a unique_ptr<SsdCache> instantiation that
// fails due to forward declaration) and instead include the umbrella Memory.h
// plus the specific vector/type headers we need.

// Workaround for libstdc++ (GCC's standard library on Linux) missing __int128
// hash support. This is needed by Folly F14 containers used internally by
// Velox. Note: macOS with libc++ (Clang's standard library) doesn't need this
// workaround as it provides __int128 hash support out of the box.
#include <cstdint>

// Only define __int128 hash specializations for libstdc++ (not libc++)
#if defined(__GLIBCXX__) && !defined(_LIBCPP_VERSION)
#include <functional>
#include <type_traits>

namespace std {
template <>
struct hash<__int128> {
  size_t operator()(__int128 value) const noexcept {
    return std::hash<uint64_t>{}(static_cast<uint64_t>(value)) ^
           (std::hash<uint64_t>{}(static_cast<uint64_t>(value >> 64)) << 1);
  }
};

template <>
struct hash<unsigned __int128> {
  size_t operator()(unsigned __int128 value) const noexcept {
    return std::hash<uint64_t>{}(static_cast<uint64_t>(value)) ^
           (std::hash<uint64_t>{}(static_cast<uint64_t>(value >> 64)) << 1);
  }
};
}  // namespace std
#endif  // __GLIBCXX__ && !_LIBCPP_VERSION

#include <gtest/gtest.h>
#include <velox/common/caching/SsdCache.h>
#include <velox/common/memory/Memory.h>
#include <velox/core/PlanNode.h>
#include <velox/type/Type.h>
#include <velox/type/Variant.h>
#include <velox/vector/ComplexVector.h>
#include <velox/vector/FlatVector.h>

#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#endif

using facebook::velox::BaseVector;
using facebook::velox::BIGINT;
using facebook::velox::BOOLEAN;
using facebook::velox::BufferPtr;
using facebook::velox::FlatVector;
using facebook::velox::INTEGER;
using facebook::velox::ROW;
using facebook::velox::RowVector;
using facebook::velox::RowVectorPtr;
using facebook::velox::StringView;
using facebook::velox::VARCHAR;
using facebook::velox::variant;
using facebook::velox::vector_size_t;
using facebook::velox::VectorPtr;
namespace core = facebook::velox::core;
namespace memory = facebook::velox::memory;

namespace {
class VeloxPipelineTest : public ::testing::Test {
 protected:
  static void SetUpTestSuite() {}
  static std::shared_ptr<memory::MemoryPool> MakeLeafPool(
      const std::string& name) {
    return memory::memoryManager()->addLeafPool(name);
  }
};
}  // namespace

TEST_F(VeloxPipelineTest, ValuesProjectFilterAggregationStructure) {
  auto pool = MakeLeafPool("pipe_struct1");
  auto input_type = ROW({"x", "category"}, {INTEGER(), VARCHAR()});
  vector_size_t size = 4;
  auto x_vec = BaseVector::create(INTEGER(), size, pool.get());
  auto c_vec = BaseVector::create(VARCHAR(), size, pool.get());
  auto* x_flat = x_vec->as<FlatVector<int32_t>>();
  auto* c_flat = c_vec->as<FlatVector<StringView>>();
  std::vector<std::string> cats = {"A", "B", "A", "B"};
  for (int i = 0; i < size; ++i) {
    x_flat->set(i, i + 1);
    c_flat->set(i, StringView(cats[i]));
  }
  auto input_row =
      std::make_shared<RowVector>(pool.get(), input_type, BufferPtr(nullptr),
                                  size, std::vector<VectorPtr>{x_vec, c_vec});
  auto values_node = std::make_shared<core::ValuesNode>(
      "values", std::vector<RowVectorPtr>{input_row});
  auto field_x = std::make_shared<core::FieldAccessTypedExpr>(INTEGER(), "x");
  auto mul_expr = std::make_shared<core::CallTypedExpr>(
      INTEGER(),
      std::vector<core::TypedExprPtr>{
          field_x,
          std::make_shared<core::ConstantTypedExpr>(INTEGER(), variant(2))},
      "multiply");
  auto project_node = std::make_shared<core::ProjectNode>(
      "project", std::vector<std::string>{"x", "category", "y"},
      std::vector<core::TypedExprPtr>{
          field_x,
          std::make_shared<core::FieldAccessTypedExpr>(VARCHAR(), "category"),
          mul_expr},
      values_node);
  auto mod_expr = std::make_shared<core::CallTypedExpr>(
      INTEGER(),
      std::vector<core::TypedExprPtr>{
          field_x,
          std::make_shared<core::ConstantTypedExpr>(INTEGER(), variant(2))},
      "modulus");
  auto eq_expr = std::make_shared<core::CallTypedExpr>(
      BOOLEAN(),
      std::vector<core::TypedExprPtr>{
          mod_expr,
          std::make_shared<core::ConstantTypedExpr>(INTEGER(), variant(0))},
      "eq");
  auto filter_node =
      std::make_shared<core::FilterNode>("filter", eq_expr, project_node);
  auto field_category =
      std::make_shared<core::FieldAccessTypedExpr>(VARCHAR(), "category");
  auto field_y = std::make_shared<core::FieldAccessTypedExpr>(INTEGER(), "y");
  core::AggregationNode::Aggregate sum_agg{
      .call = std::make_shared<core::CallTypedExpr>(
          BIGINT(), std::vector<core::TypedExprPtr>{field_y}, "sum"),
      .rawInputTypes = {INTEGER()},
      .mask = nullptr,
      .sortingKeys = {},
      .sortingOrders = {},
      .distinct = false};
  auto agg_node = std::make_shared<core::AggregationNode>(
      "agg", core::AggregationNode::Step::kSingle,
      std::vector<core::FieldAccessTypedExprPtr>{field_category},
      std::vector<core::FieldAccessTypedExprPtr>{},
      std::vector<std::string>{"sum_y"},
      std::vector<core::AggregationNode::Aggregate>{sum_agg}, true,
      filter_node);
  EXPECT_EQ(agg_node->sources().size(), 1);
  EXPECT_EQ(filter_node->sources().size(), 1);
  EXPECT_EQ(project_node->sources().size(), 1);
  EXPECT_EQ(values_node->values().size(), 1);
  EXPECT_EQ(agg_node->aggregates().size(), 1);
}

TEST_F(VeloxPipelineTest, ValuesHashJoinInnerStructure) {
  auto pool = MakeLeafPool("pipe_struct2");
  auto left_type = ROW({"id", "lv"}, {INTEGER(), INTEGER()});
  auto right_type = ROW({"rid", "rv"}, {INTEGER(), INTEGER()});
  vector_size_t lsize = 2;
  auto lid = BaseVector::create(INTEGER(), lsize, pool.get());
  auto llv = BaseVector::create(INTEGER(), lsize, pool.get());
  auto rid = BaseVector::create(INTEGER(), lsize, pool.get());
  auto rrv = BaseVector::create(INTEGER(), lsize, pool.get());
  auto left_row =
      std::make_shared<RowVector>(pool.get(), left_type, BufferPtr(nullptr),
                                  lsize, std::vector<VectorPtr>{lid, llv});
  auto right_row =
      std::make_shared<RowVector>(pool.get(), right_type, BufferPtr(nullptr),
                                  lsize, std::vector<VectorPtr>{rid, rrv});
  auto left_values = std::make_shared<core::ValuesNode>(
      "left", std::vector<RowVectorPtr>{left_row});
  auto right_values = std::make_shared<core::ValuesNode>(
      "right", std::vector<RowVectorPtr>{right_row});
  auto l_key = std::make_shared<core::FieldAccessTypedExpr>(INTEGER(), "id");
  auto r_key = std::make_shared<core::FieldAccessTypedExpr>(INTEGER(), "rid");
  auto out_type = ROW({"id", "lv", "rid", "rv"},
                      {INTEGER(), INTEGER(), INTEGER(), INTEGER()});
  auto join_node = std::make_shared<core::HashJoinNode>(
      "join", core::JoinType::kInner, false,
      std::vector<core::FieldAccessTypedExprPtr>{l_key},
      std::vector<core::FieldAccessTypedExprPtr>{r_key}, nullptr, left_values,
      right_values, out_type);
  EXPECT_EQ(join_node->sources().size(), 2);
  EXPECT_EQ(join_node->joinType(), core::JoinType::kInner);
  EXPECT_EQ(out_type->size(), 4);
}

TEST_F(VeloxPipelineTest, MultiStageAggregationStructure) {
  auto pool = MakeLeafPool("pipe_struct3");
  auto input_type = ROW({"x"}, {INTEGER()});
  vector_size_t size = 4;
  auto val_x = BaseVector::create(INTEGER(), size, pool.get());
  auto row =
      std::make_shared<RowVector>(pool.get(), input_type, BufferPtr(nullptr),
                                  size, std::vector<VectorPtr>{val_x});
  auto values = std::make_shared<core::ValuesNode>(
      "values_ms", std::vector<RowVectorPtr>{row});
  auto field_x = std::make_shared<core::FieldAccessTypedExpr>(INTEGER(), "x");
  auto mod = std::make_shared<core::CallTypedExpr>(
      INTEGER(),
      std::vector<core::TypedExprPtr>{
          field_x,
          std::make_shared<core::ConstantTypedExpr>(INTEGER(), variant(2))},
      "modulus");
  auto project = std::make_shared<core::ProjectNode>(
      "proj", std::vector<std::string>{"x", "g"},
      std::vector<core::TypedExprPtr>{field_x, mod}, values);
  auto field_g = std::make_shared<core::FieldAccessTypedExpr>(INTEGER(), "g");
  core::AggregationNode::Aggregate sum_agg{
      .call = std::make_shared<core::CallTypedExpr>(
          BIGINT(), std::vector<core::TypedExprPtr>{field_x}, "sum"),
      .rawInputTypes = {INTEGER()},
      .mask = nullptr,
      .sortingKeys = {},
      .sortingOrders = {},
      .distinct = false};
  auto partial_agg = std::make_shared<core::AggregationNode>(
      "agg_p", core::AggregationNode::Step::kPartial,
      std::vector<core::FieldAccessTypedExprPtr>{field_g},
      std::vector<core::FieldAccessTypedExprPtr>{},
      std::vector<std::string>{"sum_x"},
      std::vector<core::AggregationNode::Aggregate>{sum_agg}, true, project);
  auto field_partial =
      std::make_shared<core::FieldAccessTypedExpr>(BIGINT(), "sum_x");
  core::AggregationNode::Aggregate final_spec{
      .call = std::make_shared<core::CallTypedExpr>(
          BIGINT(), std::vector<core::TypedExprPtr>{field_partial}, "sum"),
      .rawInputTypes = {BIGINT()},
      .mask = nullptr,
      .sortingKeys = {},
      .sortingOrders = {},
      .distinct = false};
  auto final_agg = std::make_shared<core::AggregationNode>(
      "agg_f", core::AggregationNode::Step::kFinal,
      std::vector<core::FieldAccessTypedExprPtr>{field_g},
      std::vector<core::FieldAccessTypedExprPtr>{},
      std::vector<std::string>{"final_sum"},
      std::vector<core::AggregationNode::Aggregate>{final_spec}, true,
      partial_agg);
  EXPECT_EQ(partial_agg->step(), core::AggregationNode::Step::kPartial);
  EXPECT_EQ(final_agg->step(), core::AggregationNode::Step::kFinal);
  EXPECT_EQ(final_agg->sources().size(), 1);
  EXPECT_EQ(partial_agg->sources().size(), 1);
  EXPECT_EQ(project->sources().size(), 1);
  EXPECT_EQ(values->values().size(), 1);
}
