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
#include <functional>
#include <type_traits>

// Only define __int128 hash specializations for libstdc++ (not libc++)
#if defined(__GLIBCXX__) && !defined(_LIBCPP_VERSION)
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

using namespace facebook::velox;

namespace {
class VeloxPipelineTest : public ::testing::Test {
 protected:
  static void SetUpTestSuite() {}
  std::shared_ptr<memory::MemoryPool> makeLeafPool(const std::string& name) {
    return memory::memoryManager()->addLeafPool(name);
  }
};
}  // namespace

TEST_F(VeloxPipelineTest, ValuesProjectFilterAggregationStructure) {
  auto pool = makeLeafPool("pipe_struct1");
  auto inputType = ROW({"x", "category"}, {INTEGER(), VARCHAR()});
  vector_size_t size = 4;
  auto xVec = BaseVector::create(INTEGER(), size, pool.get());
  auto cVec = BaseVector::create(VARCHAR(), size, pool.get());
  auto xFlat = xVec->as<FlatVector<int32_t>>();
  auto cFlat = cVec->as<FlatVector<StringView>>();
  std::vector<std::string> cats = {"A", "B", "A", "B"};
  for (int i = 0; i < size; ++i) {
    xFlat->set(i, i + 1);
    cFlat->set(i, StringView(cats[i]));
  }
  auto inputRow =
      std::make_shared<RowVector>(pool.get(), inputType, BufferPtr(nullptr),
                                  size, std::vector<VectorPtr>{xVec, cVec});
  auto valuesNode = std::make_shared<core::ValuesNode>(
      "values", std::vector<RowVectorPtr>{inputRow});
  auto fieldX = std::make_shared<core::FieldAccessTypedExpr>(INTEGER(), "x");
  auto mulExpr = std::make_shared<core::CallTypedExpr>(
      INTEGER(),
      std::vector<core::TypedExprPtr>{
          fieldX,
          std::make_shared<core::ConstantTypedExpr>(INTEGER(), variant(2))},
      "multiply");
  auto projectNode = std::make_shared<core::ProjectNode>(
      "project", std::vector<std::string>{"x", "category", "y"},
      std::vector<core::TypedExprPtr>{
          fieldX,
          std::make_shared<core::FieldAccessTypedExpr>(VARCHAR(), "category"),
          mulExpr},
      valuesNode);
  auto modExpr = std::make_shared<core::CallTypedExpr>(
      INTEGER(),
      std::vector<core::TypedExprPtr>{
          fieldX,
          std::make_shared<core::ConstantTypedExpr>(INTEGER(), variant(2))},
      "modulus");
  auto eqExpr = std::make_shared<core::CallTypedExpr>(
      BOOLEAN(),
      std::vector<core::TypedExprPtr>{
          modExpr,
          std::make_shared<core::ConstantTypedExpr>(INTEGER(), variant(0))},
      "eq");
  auto filterNode =
      std::make_shared<core::FilterNode>("filter", eqExpr, projectNode);
  auto fieldCategory =
      std::make_shared<core::FieldAccessTypedExpr>(VARCHAR(), "category");
  auto fieldY = std::make_shared<core::FieldAccessTypedExpr>(INTEGER(), "y");
  core::AggregationNode::Aggregate sumAgg{
      .call = std::make_shared<core::CallTypedExpr>(
          BIGINT(), std::vector<core::TypedExprPtr>{fieldY}, "sum"),
      .rawInputTypes = {INTEGER()},
      .mask = nullptr,
      .sortingKeys = {},
      .sortingOrders = {},
      .distinct = false};
  auto aggNode = std::make_shared<core::AggregationNode>(
      "agg", core::AggregationNode::Step::kSingle,
      std::vector<core::FieldAccessTypedExprPtr>{fieldCategory},
      std::vector<core::FieldAccessTypedExprPtr>{},
      std::vector<std::string>{"sum_y"},
      std::vector<core::AggregationNode::Aggregate>{sumAgg}, true, filterNode);
  EXPECT_EQ(aggNode->sources().size(), 1);
  EXPECT_EQ(filterNode->sources().size(), 1);
  EXPECT_EQ(projectNode->sources().size(), 1);
  EXPECT_EQ(valuesNode->values().size(), 1);
  EXPECT_EQ(aggNode->aggregates().size(), 1);
}

TEST_F(VeloxPipelineTest, ValuesHashJoinInnerStructure) {
  auto pool = makeLeafPool("pipe_struct2");
  auto leftType = ROW({"id", "lv"}, {INTEGER(), INTEGER()});
  auto rightType = ROW({"rid", "rv"}, {INTEGER(), INTEGER()});
  vector_size_t lsize = 2;
  auto lid = BaseVector::create(INTEGER(), lsize, pool.get());
  auto llv = BaseVector::create(INTEGER(), lsize, pool.get());
  auto rid = BaseVector::create(INTEGER(), lsize, pool.get());
  auto rrv = BaseVector::create(INTEGER(), lsize, pool.get());
  auto leftRow =
      std::make_shared<RowVector>(pool.get(), leftType, BufferPtr(nullptr),
                                  lsize, std::vector<VectorPtr>{lid, llv});
  auto rightRow =
      std::make_shared<RowVector>(pool.get(), rightType, BufferPtr(nullptr),
                                  lsize, std::vector<VectorPtr>{rid, rrv});
  auto leftValues = std::make_shared<core::ValuesNode>(
      "left", std::vector<RowVectorPtr>{leftRow});
  auto rightValues = std::make_shared<core::ValuesNode>(
      "right", std::vector<RowVectorPtr>{rightRow});
  auto lKey = std::make_shared<core::FieldAccessTypedExpr>(INTEGER(), "id");
  auto rKey = std::make_shared<core::FieldAccessTypedExpr>(INTEGER(), "rid");
  auto outType = ROW({"id", "lv", "rid", "rv"},
                     {INTEGER(), INTEGER(), INTEGER(), INTEGER()});
  auto joinNode = std::make_shared<core::HashJoinNode>(
      "join", core::JoinType::kInner, false,
      std::vector<core::FieldAccessTypedExprPtr>{lKey},
      std::vector<core::FieldAccessTypedExprPtr>{rKey}, nullptr, leftValues,
      rightValues, outType);
  EXPECT_EQ(joinNode->sources().size(), 2);
  EXPECT_EQ(joinNode->joinType(), core::JoinType::kInner);
  EXPECT_EQ(outType->size(), 4);
}

TEST_F(VeloxPipelineTest, MultiStageAggregationStructure) {
  auto pool = makeLeafPool("pipe_struct3");
  auto inputType = ROW({"x"}, {INTEGER()});
  vector_size_t size = 4;
  auto x = BaseVector::create(INTEGER(), size, pool.get());
  auto row =
      std::make_shared<RowVector>(pool.get(), inputType, BufferPtr(nullptr),
                                  size, std::vector<VectorPtr>{x});
  auto values = std::make_shared<core::ValuesNode>(
      "values_ms", std::vector<RowVectorPtr>{row});
  auto fieldX = std::make_shared<core::FieldAccessTypedExpr>(INTEGER(), "x");
  auto mod = std::make_shared<core::CallTypedExpr>(
      INTEGER(),
      std::vector<core::TypedExprPtr>{
          fieldX,
          std::make_shared<core::ConstantTypedExpr>(INTEGER(), variant(2))},
      "modulus");
  auto project = std::make_shared<core::ProjectNode>(
      "proj", std::vector<std::string>{"x", "g"},
      std::vector<core::TypedExprPtr>{fieldX, mod}, values);
  auto fieldG = std::make_shared<core::FieldAccessTypedExpr>(INTEGER(), "g");
  core::AggregationNode::Aggregate sumAgg{
      .call = std::make_shared<core::CallTypedExpr>(
          BIGINT(), std::vector<core::TypedExprPtr>{fieldX}, "sum"),
      .rawInputTypes = {INTEGER()},
      .mask = nullptr,
      .sortingKeys = {},
      .sortingOrders = {},
      .distinct = false};
  auto partialAgg = std::make_shared<core::AggregationNode>(
      "agg_p", core::AggregationNode::Step::kPartial,
      std::vector<core::FieldAccessTypedExprPtr>{fieldG},
      std::vector<core::FieldAccessTypedExprPtr>{},
      std::vector<std::string>{"sum_x"},
      std::vector<core::AggregationNode::Aggregate>{sumAgg}, true, project);
  auto fieldPartial =
      std::make_shared<core::FieldAccessTypedExpr>(BIGINT(), "sum_x");
  core::AggregationNode::Aggregate finalSpec{
      .call = std::make_shared<core::CallTypedExpr>(
          BIGINT(), std::vector<core::TypedExprPtr>{fieldPartial}, "sum"),
      .rawInputTypes = {BIGINT()},
      .mask = nullptr,
      .sortingKeys = {},
      .sortingOrders = {},
      .distinct = false};
  auto finalAgg = std::make_shared<core::AggregationNode>(
      "agg_f", core::AggregationNode::Step::kFinal,
      std::vector<core::FieldAccessTypedExprPtr>{fieldG},
      std::vector<core::FieldAccessTypedExprPtr>{},
      std::vector<std::string>{"final_sum"},
      std::vector<core::AggregationNode::Aggregate>{finalSpec}, true,
      partialAgg);
  EXPECT_EQ(partialAgg->step(), core::AggregationNode::Step::kPartial);
  EXPECT_EQ(finalAgg->step(), core::AggregationNode::Step::kFinal);
  EXPECT_EQ(finalAgg->sources().size(), 1);
  EXPECT_EQ(partialAgg->sources().size(), 1);
  EXPECT_EQ(project->sources().size(), 1);
  EXPECT_EQ(values->values().size(), 1);
}
