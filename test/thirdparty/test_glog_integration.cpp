#include <gflags/gflags.h>
#include <glog/logging.h>
#include <gtest/gtest.h>

#include <chrono>
#include <filesystem>
#include <numbers>
#include <thread>
#include <vector>

// Test fixture for glog integration tests
class GlogIntegrationTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // Initialize Google logging
    // Use a test-specific log directory
    test_log_dir_ = std::filesystem::temp_directory_path() / "glog_test";
    std::filesystem::create_directories(test_log_dir_);

    // Set log destination to our test directory
    FLAGS_log_dir = test_log_dir_.string();
    FLAGS_logtostderr = false;
    FLAGS_alsologtostderr = false;
    FLAGS_minloglevel = google::GLOG_INFO;

    google::InitGoogleLogging("glog_test");
  }

  void TearDown() override {
    // Clean up logging
    google::ShutdownGoogleLogging();

    // Clean up test log files
    std::error_code error_code;
    std::filesystem::remove_all(test_log_dir_, error_code);
  }

 private:
  std::filesystem::path test_log_dir_;
};

// Test basic logging functionality
TEST_F(GlogIntegrationTest, BasicLogging) {
  // Test INFO level logging
  LOG(INFO) << "This is an info message";

  // Test WARNING level logging
  LOG(WARNING) << "This is a warning message";

  // Test ERROR level logging
  LOG(ERROR) << "This is an error message";

  // Flush logs to ensure they are written
  google::FlushLogFiles(google::GLOG_INFO);

  // Basic check - if we get here without crashing, logging is working
  SUCCEED();
}

// Test different log levels
TEST_F(GlogIntegrationTest, LogLevels) {
  // Set minimum log level to INFO
  FLAGS_minloglevel = google::GLOG_INFO;

  // These should be logged
  LOG(INFO) << "Info message should appear";
  LOG(WARNING) << "Warning message should appear";
  LOG(ERROR) << "Error message should appear";

  // Flush logs
  google::FlushLogFiles(google::GLOG_INFO);

  SUCCEED();
}

// Test conditional logging
TEST_F(GlogIntegrationTest, ConditionalLogging) {
  bool condition_true = true;
  bool condition_false = false;

  // Test LOG_IF
  LOG_IF(INFO, condition_true) << "This should be logged";
  LOG_IF(INFO, condition_false) << "This should NOT be logged";

  // Test LOG_EVERY_N
  for (int i = 0; i < 10; ++i) {
    LOG_EVERY_N(INFO, 3) << "Every 3rd iteration: " << i;
  }

  // Test LOG_FIRST_N
  for (int i = 0; i < 10; ++i) {
    LOG_FIRST_N(INFO, 3) << "First 3 iterations: " << i;
  }

  google::FlushLogFiles(google::GLOG_INFO);

  SUCCEED();
}

// Test VLOG (verbose logging)
TEST_F(GlogIntegrationTest, VerboseLogging) {
  // Set verbose level
  FLAGS_v = 2;

  // Test VLOG with different levels
  VLOG(1) << "Verbose level 1 message";
  VLOG(2) << "Verbose level 2 message";
  VLOG(3) << "Verbose level 3 message (should not appear)";

  google::FlushLogFiles(google::GLOG_INFO);

  SUCCEED();
}

// Test CHECK macros (these will abort on failure, so use carefully)
TEST_F(GlogIntegrationTest, CheckMacros) {
  int val_a = 5;
  int val_b = 10;

  // These should pass
  CHECK_LT(val_a, val_b) << "a should be less than b";
  CHECK_GT(val_b, val_a) << "b should be greater than a";
  CHECK_EQ(val_a, 5) << "a should equal 5";
  CHECK_NE(val_a, val_b) << "a should not equal b";

  // Test CHECK with pointer
  std::string value = "test";
  std::string* ptr = &value;
  CHECK(ptr != nullptr) << "ptr should not be null";

  SUCCEED();
}

// Test string operations with logging
TEST_F(GlogIntegrationTest, StringFormatting) {
  std::string name = "World";
  int number = 42;
  double pi_val = std::numbers::pi;

  // Test various formatting scenarios
  LOG(INFO) << "Hello, " << name << "!";
  LOG(INFO) << "Number: " << number << ", Pi: " << pi_val;
  LOG(INFO) << "Formatted message with multiple types";

  google::FlushLogFiles(google::GLOG_INFO);

  SUCCEED();
}

// Test performance logging
TEST_F(GlogIntegrationTest, PerformanceLogging) {
  auto start = std::chrono::high_resolution_clock::now();

  // Simulate some work
  for (int i = 0; i < 1000; ++i) {
    LOG_EVERY_N(INFO, 100) << "Progress: " << i;
  }

  auto end = std::chrono::high_resolution_clock::now();
  auto duration =
      std::chrono::duration_cast<std::chrono::milliseconds>(end - start);

  LOG(INFO) << "Performance test completed in " << duration.count() << " ms";

  google::FlushLogFiles(google::GLOG_INFO);

  // Verify that logging doesn't take too long (basic performance check)
  EXPECT_LT(duration.count(), 1000) << "Logging should be reasonably fast";
}

// Test thread safety (basic test)
TEST_F(GlogIntegrationTest, ThreadSafety) {
  // Create multiple threads that log simultaneously
  std::vector<std::thread> threads;
  const int NUM_THREADS = 4;
  const int MESSAGES_PER_THREAD = 100;

  threads.reserve(NUM_THREADS);
  for (int thread_idx = 0; thread_idx < NUM_THREADS; ++thread_idx) {
    threads.emplace_back([thread_idx]() {
      for (int i = 0; i < MESSAGES_PER_THREAD; ++i) {
        LOG(INFO) << "Thread " << thread_idx << " message " << i;
      }
    });
  }

  // Wait for all threads to complete
  for (auto& thread : threads) {
    thread.join();
  }

  google::FlushLogFiles(google::GLOG_INFO);

  SUCCEED();
}

// Test glog with gflags integration
TEST_F(GlogIntegrationTest, GflagsIntegration) {
  // Test that glog can work with gflags
  // This is important since glog depends on gflags

  // Change log level via flag
  FLAGS_minloglevel = google::GLOG_WARNING;

  LOG(INFO) << "This info message should be suppressed";
  LOG(WARNING) << "This warning message should appear";
  LOG(ERROR) << "This error message should appear";

  google::FlushLogFiles(google::GLOG_WARNING);

  SUCCEED();
}

int main(int argc, char** argv) {
  // Initialize gflags
  gflags::ParseCommandLineFlags(&argc, &argv, true);

  // Initialize Google Test
  ::testing::InitGoogleTest(&argc, argv);

  int result = RUN_ALL_TESTS();

  // Clean up gflags
  gflags::ShutDownCommandLineFlags();

  return result;
}
