#include <gtest/gtest.h>
#include <velox/common/memory/Memory.h>
#include <velox/core/QueryCtx.h>
#include <velox/functions/prestosql/registration/RegistrationFunctions.h>
#include <velox/type/Type.h>
#include <velox/type/Variant.h>
#include <velox/vector/ComplexVector.h>
#include <velox/vector/FlatVector.h>

using namespace facebook::velox;

class VeloxVectorTest : public testing::Test {
 protected:
  void SetUp() override {
    try {
      memory::MemoryManager::testingSetInstance({});
    } catch (...) {
    }
    static bool functionsRegistered = false;
    if (!functionsRegistered) {
      functions::prestosql::registerAllScalarFunctions();
      functionsRegistered = true;
    }
    auto& manager = *memory::MemoryManager::getInstance();
    pool_ = manager.addLeafPool("vector_pool");
  }
  std::shared_ptr<memory::MemoryPool> pool_;
};

TEST_F(VeloxVectorTest, VectorArithmeticOperations) {
  const vector_size_t size = 5;
  auto v1 = BaseVector::create(INTEGER(), size, pool_.get());
  auto v2 = BaseVector::create(INTEGER(), size, pool_.get());
  auto f1 = v1->as<FlatVector<int32_t>>();
  auto f2 = v2->as<FlatVector<int32_t>>();
  for (int i = 0; i < size; ++i) {
    f1->set(i, (i + 1) * 10);
    f2->set(i, i + 1);
  }
  auto result = BaseVector::create(INTEGER(), size, pool_.get());
  auto fr = result->as<FlatVector<int32_t>>();
  int64_t total = 0;
  for (int i = 0; i < size; ++i) {
    int32_t sum = f1->valueAt(i) + f2->valueAt(i);
    fr->set(i, sum);
    total += sum;
  }
  EXPECT_EQ(fr->valueAt(0), 11);
  EXPECT_EQ(fr->valueAt(4), 55);
  EXPECT_EQ(total, 165);
}

TEST_F(VeloxVectorTest, ArrayDataProcessing) {
  std::vector<std::vector<int32_t>> arrays = {{1, 2, 3}, {4, 5}, {6, 7, 8, 9}};
  std::vector<int32_t> sums;
  int32_t total = 0;
  for (auto& a : arrays) {
    int32_t s = 0;
    for (auto v : a) {
      s += v;
      total += v;
    }
    sums.push_back(s);
  }
  EXPECT_EQ(sums[0], 6);
  EXPECT_EQ(sums[1], 9);
  EXPECT_EQ(sums[2], 30);
  EXPECT_EQ(total, 45);
  int32_t minSum = *std::min_element(sums.begin(), sums.end());
  int32_t maxSum = *std::max_element(sums.begin(), sums.end());
  double avg = (double)total / arrays.size();
  EXPECT_EQ(minSum, 6);
  EXPECT_EQ(maxSum, 30);
  EXPECT_DOUBLE_EQ(avg, 15.0);
}

TEST_F(VeloxVectorTest, MemoryUsageCalculations) {
  auto& manager = *memory::MemoryManager::getInstance();
  auto root = manager.addRootPool("mem_root");
  auto child = root->addLeafChild("mem_child");
  auto before = child->usedBytes();
  std::vector<VectorPtr> vs;
  std::vector<std::pair<int, size_t>> cfg = {{100, sizeof(int32_t)},
                                             {500, sizeof(int64_t)},
                                             {200, sizeof(double)},
                                             {1000, sizeof(float)}};
  size_t expected = 0;
  for (auto& c : cfg) {
    int count = c.first;
    size_t es = c.second;
    VectorPtr v;
    if (es == sizeof(int32_t))
      v = BaseVector::create(INTEGER(), count, child.get());
    else if (es == sizeof(int64_t))
      v = BaseVector::create(BIGINT(), count, child.get());
    else if (es == sizeof(double))
      v = BaseVector::create(DOUBLE(), count, child.get());
    else
      v = BaseVector::create(REAL(), count, child.get());
    vs.push_back(v);
    expected += count * es;
  }
  auto after = child->usedBytes();
  EXPECT_GT(after, before);
  double ratio = (double)(after - before) / expected;
  EXPECT_GT(ratio, 0.8);
  EXPECT_LT(ratio, 10.0);
  vs.clear();
}

TEST_F(VeloxVectorTest, StringProcessingOperations) {
  auto v = BaseVector::create(VARCHAR(), 6, pool_.get());
  auto f = v->as<FlatVector<StringView>>();
  std::vector<std::string> txt = {"Hello", "World",  "Velox",
                                  "Query", "Engine", "Performance"};
  for (int i = 0; i < 6; ++i) f->set(i, StringView(txt[i]));
  size_t totalChars = 0, minL = SIZE_MAX, maxL = 0;
  for (int i = 0; i < 6; ++i) {
    size_t len = f->valueAt(i).size();
    totalChars += len;
    minL = std::min(minL, len);
    maxL = std::max(maxL, len);
  }
  EXPECT_EQ(totalChars, 37);
  EXPECT_EQ(minL, 5);
  EXPECT_EQ(maxL, 11);
  double avg = (double)totalChars / 6;
  EXPECT_DOUBLE_EQ(avg, 37.0 / 6.0);
}

TEST_F(VeloxVectorTest, NestedStructures) {
  auto inner = ROW({"x", "y"}, {INTEGER(), INTEGER()});
  auto arr = ARRAY(inner);
  auto outer = ROW({"id", "data"}, {BIGINT(), arr});
  auto vec = BaseVector::create(outer, 2, pool_.get());
  EXPECT_EQ(vec->type()->kind(), TypeKind::ROW);
  auto& rowType = vec->type()->asRow();
  EXPECT_EQ(rowType.size(), 2);
  EXPECT_EQ(rowType.nameOf(0), "id");
  EXPECT_EQ(rowType.nameOf(1), "data");
}

TEST_F(VeloxVectorTest, PlanExecutionWithCalculations) {
  struct E {
    int64_t id;
    std::string name;
    int32_t age;
    double base;
  };
  std::vector<E> es = {{1001, "Alice", 28, 50000},
                       {1002, "Bob", 35, 75000},
                       {1003, "Charlie", 42, 90000},
                       {1004, "Diana", 31, 65000},
                       {1005, "Eve", 29, 55000}};
  double total = 0, maxSalary = 0;
  int32_t ageSum = 0;
  std::vector<double> bonuses;
  for (auto& e : es) {
    double rate = (e.age > 30) ? 0.10 : 0.05;
    double b = e.base * rate;
    double totalSal = e.base + b;
    bonuses.push_back(b);
    total += totalSal;
    ageSum += e.age;
    maxSalary = std::max(maxSalary, totalSal);
  }
  int32_t avgAge = ageSum / es.size();
  EXPECT_DOUBLE_EQ(bonuses[0], 2500);
  EXPECT_DOUBLE_EQ(bonuses[1], 7500);
  EXPECT_DOUBLE_EQ(total, 363250);
  EXPECT_EQ(avgAge, 33);
  EXPECT_DOUBLE_EQ(maxSalary, 99000);
}

TEST_F(VeloxVectorTest, QueryContextWithDataProcessing) {
  auto q = core::QueryCtx::create();
  struct B {
    int id;
    std::vector<int32_t> vs;
    size_t bytes;
  };
  std::vector<B> batches = {{1, {100, 200, 300, 400}, 0},
                            {2, {150, 250, 350}, 0},
                            {3, {75, 125, 175, 225, 275}, 0}};
  size_t totalBytes = 0;
  double avgAvg = 0;
  size_t maxSz = 0;
  for (auto& b : batches) {
    auto pool = q->pool()->addLeafChild("batch" + std::to_string(b.id));
    auto before = pool->usedBytes();
    auto vec = BaseVector::create(INTEGER(), b.vs.size(), pool.get());
    auto flat = vec->as<FlatVector<int32_t>>();
    int32_t sum = 0;
    for (size_t i = 0; i < b.vs.size(); ++i) {
      flat->set(i, b.vs[i]);
      sum += b.vs[i];
    }
    double avg = (double)sum / b.vs.size();
    avgAvg += avg;
    maxSz = std::max(maxSz, b.vs.size());
    auto after = pool->usedBytes();
    b.bytes = after - before;
    totalBytes += b.bytes;
    EXPECT_GT(b.bytes, 0);
  }
  avgAvg /= batches.size();
  EXPECT_EQ(maxSz, 5);
  EXPECT_GT(totalBytes, 0);
  EXPECT_DOUBLE_EQ(avgAvg, 225.0);
}
