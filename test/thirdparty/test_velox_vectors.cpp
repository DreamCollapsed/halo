#include <gtest/gtest.h>
#include <velox/common/memory/Memory.h>
#include <velox/core/QueryCtx.h>
#include <velox/functions/prestosql/registration/RegistrationFunctions.h>
#include <velox/type/Type.h>
#include <velox/type/Variant.h>
#include <velox/vector/ComplexVector.h>
#include <velox/vector/FlatVector.h>

#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#endif

using facebook::velox::ARRAY;
using facebook::velox::BaseVector;
using facebook::velox::BIGINT;
using facebook::velox::DOUBLE;
using facebook::velox::FlatVector;
using facebook::velox::INTEGER;
using facebook::velox::REAL;
using facebook::velox::ROW;
using facebook::velox::StringView;
using facebook::velox::TypeKind;
using facebook::velox::VARCHAR;
using facebook::velox::vector_size_t;
using facebook::velox::VectorPtr;
namespace functions = facebook::velox::functions;
namespace memory = facebook::velox::memory;
namespace core = facebook::velox::core;

class VeloxVectorTest : public testing::Test {
 protected:
  void SetUp() override {
    try {
      memory::MemoryManager::testingSetInstance({});
    } catch (const std::exception& /*e*/) {  // NOLINT(bugprone-empty-catch)
    } catch (...) {                          // NOLINT(bugprone-empty-catch)
    }
    static bool functions_registered = false;
    if (!functions_registered) {
      functions::prestosql::registerAllScalarFunctions();
      functions_registered = true;
    }
    auto& manager = *memory::MemoryManager::getInstance();
    pool_ = manager.addLeafPool("vector_pool");
  }
  // NOLINTNEXTLINE(cppcoreguidelines-non-private-member-variables-in-classes,misc-non-private-member-variables-in-classes)
  std::shared_ptr<memory::MemoryPool> pool_;
};

TEST_F(VeloxVectorTest, VectorArithmeticOperations) {
  vector_size_t vector_size = 5;
  auto vec1 = BaseVector::create(INTEGER(), vector_size, pool_.get());
  auto vec2 = BaseVector::create(INTEGER(), vector_size, pool_.get());
  auto* flat1 = vec1->as<FlatVector<int32_t>>();
  auto* flat2 = vec2->as<FlatVector<int32_t>>();
  for (int i = 0; i < vector_size; ++i) {
    flat1->set(i, (i + 1) * 10);
    flat2->set(i, i + 1);
  }
  auto result = BaseVector::create(INTEGER(), vector_size, pool_.get());
  auto* flat_result = result->as<FlatVector<int32_t>>();
  int64_t total = 0;
  for (int i = 0; i < vector_size; ++i) {
    int32_t sum = flat1->valueAt(i) + flat2->valueAt(i);
    flat_result->set(i, sum);
    total += sum;
  }
  EXPECT_EQ(flat_result->valueAt(0), 11);
  EXPECT_EQ(flat_result->valueAt(4), 55);
  EXPECT_EQ(total, 165);
}

TEST_F(VeloxVectorTest, ArrayDataProcessing) {
  std::vector<std::vector<int32_t>> arrays = {{1, 2, 3}, {4, 5}, {6, 7, 8, 9}};
  std::vector<int32_t> sums;
  int32_t total = 0;
  for (auto& arr : arrays) {
    int32_t sum = 0;
    for (auto val : arr) {
      sum += val;
      total += val;
    }
    sums.push_back(sum);
  }
  EXPECT_EQ(sums[0], 6);
  EXPECT_EQ(sums[1], 9);
  EXPECT_EQ(sums[2], 30);
  EXPECT_EQ(total, 45);
  // NOLINTNEXTLINE(modernize-use-ranges)
  int32_t min_sum = *std::min_element(sums.begin(), sums.end());
  // NOLINTNEXTLINE(modernize-use-ranges)
  int32_t max_sum = *std::max_element(sums.begin(), sums.end());
  // NOLINTNEXTLINE(bugprone-narrowing-conversions,cppcoreguidelines-narrowing-conversions)
  double avg = static_cast<double>(total) / arrays.size();
  EXPECT_EQ(min_sum, 6);
  EXPECT_EQ(max_sum, 30);
  EXPECT_DOUBLE_EQ(avg, 15.0);
}

TEST_F(VeloxVectorTest, MemoryUsageCalculations) {
  auto& manager = *memory::MemoryManager::getInstance();
  auto root = manager.addRootPool("mem_root");
  auto child = root->addLeafChild("mem_child");
  auto before = child->usedBytes();
  std::vector<VectorPtr> vectors;
  std::vector<std::pair<int, size_t>> config = {{100, sizeof(int32_t)},
                                                {500, sizeof(int64_t)},
                                                {200, sizeof(double)},
                                                {1000, sizeof(float)}};
  size_t expected = 0;
  for (auto& conf : config) {
    int count = conf.first;
    size_t element_size = conf.second;
    VectorPtr vec;
    if (element_size == sizeof(int32_t)) {
      vec = BaseVector::create(INTEGER(), count, child.get());
    } else if (element_size == sizeof(int64_t)) {
      vec = BaseVector::create(BIGINT(), count, child.get());
    } else if (element_size == sizeof(double)) {
      vec = BaseVector::create(DOUBLE(), count, child.get());
    } else {
      vec = BaseVector::create(REAL(), count, child.get());
    }
    vectors.push_back(vec);
    expected += count * element_size;
  }
  auto after = child->usedBytes();
  EXPECT_GT(after, before);
  // NOLINTNEXTLINE(bugprone-narrowing-conversions,cppcoreguidelines-narrowing-conversions)
  double ratio = static_cast<double>(after - before) / expected;
  EXPECT_GT(ratio, 0.8);
  EXPECT_LT(ratio, 10.0);
  vectors.clear();
}

TEST_F(VeloxVectorTest, StringProcessingOperations) {
  auto vec = BaseVector::create(VARCHAR(), 6, pool_.get());
  auto* flat = vec->as<FlatVector<StringView>>();
  std::vector<std::string> text_data = {"Hello", "World",  "Velox",
                                        "Query", "Engine", "Performance"};
  for (int i = 0; i < 6; ++i) {
    flat->set(i, StringView(text_data[i]));
  }
  size_t total_chars = 0;
  size_t min_len = SIZE_MAX;
  size_t max_len = 0;
  for (int i = 0; i < 6; ++i) {
    size_t len = flat->valueAt(i).size();
    total_chars += len;
    min_len = std::min(min_len, len);
    max_len = std::max(max_len, len);
  }
  EXPECT_EQ(total_chars, 37);
  EXPECT_EQ(min_len, 5);
  EXPECT_EQ(max_len, 11);
  double avg = static_cast<double>(total_chars) / 6;
  EXPECT_DOUBLE_EQ(avg, 37.0 / 6.0);
}

TEST_F(VeloxVectorTest, NestedStructures) {
  auto inner = ROW({"x", "y"}, {INTEGER(), INTEGER()});
  auto arr = ARRAY(inner);
  auto outer = ROW({"id", "data"}, {BIGINT(), arr});
  auto vec = BaseVector::create(outer, 2, pool_.get());
  EXPECT_EQ(vec->type()->kind(), TypeKind::ROW);
  const auto& row_type = vec->type()->asRow();
  EXPECT_EQ(row_type.size(), 2);
  EXPECT_EQ(row_type.nameOf(0), "id");
  EXPECT_EQ(row_type.nameOf(1), "data");
}

TEST_F(VeloxVectorTest, PlanExecutionWithCalculations) {
  struct E {
    int64_t id_;
    std::string name_;
    int32_t age_;
    double base_;
  };
  std::vector<E> employees = {{1001, "Alice", 28, 50000},
                              {1002, "Bob", 35, 75000},
                              {1003, "Charlie", 42, 90000},
                              {1004, "Diana", 31, 65000},
                              {1005, "Eve", 29, 55000}};
  double total_salary = 0;
  double max_salary = 0;
  int32_t age_sum = 0;
  std::vector<double> bonuses;
  for (auto& emp : employees) {
    double rate = (emp.age_ > 30) ? 0.10 : 0.05;
    double bonus = emp.base_ * rate;
    double total_sal = emp.base_ + bonus;
    bonuses.push_back(bonus);
    total_salary += total_sal;
    age_sum += emp.age_;
    max_salary = std::max(max_salary, total_sal);
  }
  // NOLINTNEXTLINE(bugprone-narrowing-conversions,cppcoreguidelines-narrowing-conversions)
  int32_t avg_age = age_sum / employees.size();
  EXPECT_DOUBLE_EQ(bonuses[0], 2500);
  EXPECT_DOUBLE_EQ(bonuses[1], 7500);
  EXPECT_DOUBLE_EQ(total_salary, 363250);
  EXPECT_EQ(avg_age, 33);
  EXPECT_DOUBLE_EQ(max_salary, 99000);
}

TEST_F(VeloxVectorTest, QueryContextWithDataProcessing) {
  auto query_ctx = core::QueryCtx::create();
  struct B {
    int id_;
    std::vector<int32_t> values_;
    size_t bytes_;
  };
  std::vector<B> batch_list = {{1, {100, 200, 300, 400}, 0},
                               {2, {150, 250, 350}, 0},
                               {3, {75, 125, 175, 225, 275}, 0}};
  size_t total_bytes = 0;
  double avg_average = 0;
  size_t max_size = 0;
  for (auto& batch : batch_list) {
    auto pool =
        query_ctx->pool()->addLeafChild("batch" + std::to_string(batch.id_));
    auto before = pool->usedBytes();
    auto vector = BaseVector::create(
        INTEGER(), static_cast<vector_size_t>(batch.values_.size()),
        pool.get());
    auto* flat_vec = vector->as<FlatVector<int32_t>>();
    int32_t sum = 0;
    for (size_t i = 0; i < batch.values_.size(); ++i) {
      // NOLINTNEXTLINE(bugprone-narrowing-conversions,cppcoreguidelines-narrowing-conversions)
      flat_vec->set(i, batch.values_[i]);
      sum += batch.values_[i];
    }
    // NOLINTNEXTLINE(bugprone-narrowing-conversions,cppcoreguidelines-narrowing-conversions)
    double avg = static_cast<double>(sum) / batch.values_.size();
    avg_average += avg;
    max_size = std::max(max_size, batch.values_.size());
    auto after = pool->usedBytes();
    batch.bytes_ = after - before;
    total_bytes += batch.bytes_;
    EXPECT_GT(batch.bytes_, 0);
  }
  // NOLINTNEXTLINE(bugprone-narrowing-conversions,cppcoreguidelines-narrowing-conversions)
  avg_average /= batch_list.size();
  EXPECT_EQ(max_size, 5);
  EXPECT_GT(total_bytes, 0);
  EXPECT_DOUBLE_EQ(avg_average, 225.0);
}
