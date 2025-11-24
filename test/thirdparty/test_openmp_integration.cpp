#include <gtest/gtest.h>
#include <omp.h>

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <thread>
#include <vector>

// Test fixture for OpenMP integration tests
class OpenMPIntegrationTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // Store original number of threads
    original_num_threads_ = omp_get_max_threads();
  }

  void TearDown() override {
    // Restore original number of threads
    omp_set_num_threads(original_num_threads_);
  }

  [[nodiscard]] int OriginalNumThreads() const { return original_num_threads_; }

 private:
  int original_num_threads_ = 0;
};

// Test basic OpenMP functionality
TEST_F(OpenMPIntegrationTest, BasicOpenMPTest) {
  // Test that OpenMP is available
  EXPECT_TRUE(omp_get_max_threads() > 0);

  // Test thread number functions
  int max_threads = omp_get_max_threads();
  EXPECT_GT(max_threads, 0);

  // Set a specific number of threads
  int test_threads = std::min(4, max_threads);
  omp_set_num_threads(test_threads);

  EXPECT_EQ(omp_get_max_threads(), test_threads);
}

// Test parallel for loop
TEST_F(OpenMPIntegrationTest, ParallelForLoop) {
  int data_size = 10000;
  std::vector<int> data(data_size);

// Initialize data with sequential values
#pragma omp parallel for
  for (int i = 0; i < data_size; ++i) {
    data[i] = i * 2;
  }

  // Verify results
  for (int i = 0; i < data_size; ++i) {
    EXPECT_EQ(data[i], i * 2);
  }
}

// Test parallel reduction
TEST_F(OpenMPIntegrationTest, ParallelReduction) {
  int data_size = 100000;
  std::vector<int> data(data_size);

  // Initialize data
  for (int i = 0; i < data_size; ++i) {
    data[i] = i + 1;
  }

  // Calculate sum using OpenMP reduction
  int64_t parallel_sum = 0;
#pragma omp parallel for reduction(+ : parallel_sum)
  for (int i = 0; i < data_size; ++i) {
    parallel_sum += data[i];
  }

  // Calculate expected sum: 1 + 2 + ... + N = N*(N+1)/2
  int64_t expected_sum = static_cast<int64_t>(data_size) * (data_size + 1) / 2;

  EXPECT_EQ(parallel_sum, expected_sum);
}

// Test thread-private variables
TEST_F(OpenMPIntegrationTest, ThreadPrivateVariables) {
  int num_threads = std::min(4, omp_get_max_threads());
  omp_set_num_threads(num_threads);

  std::vector<int> thread_ids(num_threads, -1);
  std::vector<bool> thread_used(num_threads, false);

#pragma omp parallel
  {
    int tid = omp_get_thread_num();
    int total_threads = omp_get_num_threads();

    // Ensure we're running in parallel
    EXPECT_GT(total_threads, 1);
    EXPECT_GE(tid, 0);
    EXPECT_LT(tid, total_threads);

// Record thread usage
#pragma omp critical
    {
      thread_ids[tid] = tid;
      thread_used[tid] = true;
    }
  }

  // Verify all threads were used
  for (int i = 0; i < num_threads; ++i) {
    EXPECT_TRUE(thread_used[i]) << "Thread " << i << " was not used";
    EXPECT_EQ(thread_ids[i], i);
  }
}

// Test OpenMP sections
TEST_F(OpenMPIntegrationTest, ParallelSections) {
  std::vector<bool> section_executed(3, false);

#pragma omp parallel sections
  {
#pragma omp section
    {
      section_executed[0] = true;
      std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }

#pragma omp section
    {
      section_executed[1] = true;
      std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }

#pragma omp section
    {
      section_executed[2] = true;
      std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
  }

  // Verify all sections were executed
  for (int i = 0; i < 3; ++i) {
    EXPECT_TRUE(section_executed[i]) << "Section " << i << " was not executed";
  }
}

// Test OpenMP critical sections
TEST_F(OpenMPIntegrationTest, CriticalSections) {
  int num_iterations = 1000;
  int shared_counter = 0;

#pragma omp parallel for
  for (int i = 0; i < num_iterations; ++i) {
#pragma omp critical
    {
      shared_counter++;
    }
  }

  EXPECT_EQ(shared_counter, num_iterations);
}

// Test OpenMP atomic operations
TEST_F(OpenMPIntegrationTest, AtomicOperations) {
  int num_iterations = 10000;
  int atomic_counter = 0;

#pragma omp parallel for
  for (int i = 0; i < num_iterations; ++i) {
#pragma omp atomic
    atomic_counter++;
  }

  EXPECT_EQ(atomic_counter, num_iterations);
}

// Test OpenMP barriers
TEST_F(OpenMPIntegrationTest, Barriers) {
  int num_threads = std::min(4, omp_get_max_threads());
  omp_set_num_threads(num_threads);

  std::vector<int> phase1_complete(num_threads, 0);
  std::vector<int> phase2_complete(num_threads, 0);

#pragma omp parallel
  {
    int tid = omp_get_thread_num();

    // Phase 1: Each thread sets its completion flag
    phase1_complete[tid] = 1;

// Barrier: Wait for all threads to complete phase 1
#pragma omp barrier

    // Phase 2: Verify all threads completed phase 1
    for (int i = 0; i < num_threads; ++i) {
      EXPECT_EQ(phase1_complete[i], 1)
          << "Thread " << i << " did not complete phase 1";
    }

    phase2_complete[tid] = 1;
  }

  // Verify all threads completed phase 2
  for (int i = 0; i < num_threads; ++i) {
    EXPECT_EQ(phase2_complete[i], 1)
        << "Thread " << i << " did not complete phase 2";
  }
}

// Performance test: Compare sequential vs parallel execution
TEST_F(OpenMPIntegrationTest, PerformanceComparison) {
  int data_size = 1000000;
  std::vector<double> data(data_size);
  std::vector<double> result_seq(data_size);
  std::vector<double> result_par(data_size);

  // Initialize data
  for (int i = 0; i < data_size; ++i) {
    data[i] = static_cast<double>(i + 1);
  }

  // Sequential execution
  auto start_seq = std::chrono::high_resolution_clock::now();
  for (int i = 0; i < data_size; ++i) {
    result_seq[i] = std::sqrt(data[i]) * std::sin(data[i] / 1000.0);
  }
  auto end_seq = std::chrono::high_resolution_clock::now();

  // Parallel execution
  auto start_par = std::chrono::high_resolution_clock::now();
#pragma omp parallel for
  for (int i = 0; i < data_size; ++i) {
    result_par[i] = std::sqrt(data[i]) * std::sin(data[i] / 1000.0);
  }
  auto end_par = std::chrono::high_resolution_clock::now();

  // Calculate execution times
  auto seq_duration = std::chrono::duration_cast<std::chrono::milliseconds>(
      end_seq - start_seq);
  auto par_duration = std::chrono::duration_cast<std::chrono::milliseconds>(
      end_par - start_par);

  // Verify results are identical
  for (int i = 0; i < data_size; ++i) {
    EXPECT_DOUBLE_EQ(result_seq[i], result_par[i]);
  }

  // Log performance information
  std::cout << "Sequential time: " << seq_duration.count() << " ms"
            << "\n";
  std::cout << "Parallel time: " << par_duration.count() << " ms" << "\n";

  if (omp_get_max_threads() > 1) {
    double speedup = static_cast<double>(seq_duration.count()) /
                     static_cast<double>(par_duration.count());
    std::cout << "Speedup: " << speedup << "x" << "\n";

    // Expect some speedup with multiple threads (very lenient test)
    EXPECT_GT(speedup, 0.5);  // Allow for overhead
  }
}

// Test OpenMP version and features
TEST_F(OpenMPIntegrationTest, OpenMPVersionTest) {
// Test OpenMP version using compile-time macro
#ifdef _OPENMP
  int version = _OPENMP;
  std::cout << "OpenMP version: " << version << "\n";

  // OpenMP 4.0 was released in 2013, so we expect at least that
  EXPECT_GE(version, 201307);  // OpenMP 4.0
#else
  FAIL() << "OpenMP not available";
#endif
}

// Test nested parallelism (if supported)
TEST_F(OpenMPIntegrationTest, NestedParallelism) {
  // Enable nested parallelism
  omp_set_nested(1);

  bool nested_supported = (omp_get_nested() != 0);
  std::cout << "Nested parallelism supported: "
            << (nested_supported ? "Yes" : "No") << "\n";

  if (nested_supported) {
    std::vector<int> outer_threads;
    std::vector<int> inner_threads;

#pragma omp parallel num_threads(2)
    {
      int outer_tid = omp_get_thread_num();

#pragma omp parallel num_threads(2)
      {
        int inner_tid = omp_get_thread_num();

#pragma omp critical
        {
          outer_threads.push_back(outer_tid);
          inner_threads.push_back(inner_tid);
        }
      }
    }

    // We should have executed nested parallel regions
    EXPECT_GT(outer_threads.size(), 0);
    EXPECT_GT(inner_threads.size(), 0);
  }

  // Disable nested parallelism
  omp_set_nested(0);
}

int main(int argc, char** argv) {
  ::testing::InitGoogleTest(&argc, argv);

  // Print OpenMP information
  std::cout << "OpenMP max threads: " << omp_get_max_threads() << "\n";
#ifdef _OPENMP
  std::cout << "OpenMP version: " << _OPENMP << "\n";
#endif

  return RUN_ALL_TESTS();
}
