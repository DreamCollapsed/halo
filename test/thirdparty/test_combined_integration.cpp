#include <absl/container/flat_hash_map.h>
#include <absl/container/flat_hash_set.h>
#include <absl/hash/hash.h>
#include <absl/status/status.h>
#include <absl/status/statusor.h>
#include <absl/strings/ascii.h>
#include <absl/strings/str_cat.h>
#include <absl/strings/str_format.h>
#include <absl/strings/str_join.h>
#include <absl/strings/str_split.h>
#include <absl/strings/string_view.h>
#include <absl/time/clock.h>
#include <absl/time/time.h>
#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include <memory>
#include <numeric>
#include <string>
#include <vector>

using ::testing::_;
using ::testing::ElementsAre;
using ::testing::Eq;
using ::testing::HasSubstr;
using ::testing::Return;

// Mock logger interface using Abseil types
class MockLogger {
 public:
  virtual ~MockLogger() = default;
  virtual absl::Status Log(absl::string_view level,
                           absl::string_view message) = 0;
  virtual absl::StatusOr<std::string> GetLastLog() = 0;
  virtual void SetTimestamp(absl::Time timestamp) = 0;
};

class MockLoggerImpl : public MockLogger {
 public:
  MOCK_METHOD(absl::Status, Log,
              (absl::string_view level, absl::string_view message), (override));
  MOCK_METHOD(absl::StatusOr<std::string>, GetLastLog, (), (override));
  MOCK_METHOD(void, SetTimestamp, (absl::Time timestamp), (override));
};

// Service that combines Abseil data structures with mockable interfaces
class DataProcessingService {
 public:
  explicit DataProcessingService(std::unique_ptr<MockLogger> logger)
      : logger_(std::move(logger)) {}

  absl::StatusOr<absl::flat_hash_map<std::string, int>> ProcessCsvData(
      absl::string_view csv_data) {
    if (csv_data.empty()) {
      return absl::InvalidArgumentError("CSV data cannot be empty");
    }

    // Log the start of processing
    auto log_status = logger_->Log(
        "INFO",
        absl::StrFormat("Processing CSV data of size %d", csv_data.size()));
    if (!log_status.ok()) {
      return log_status;
    }

    absl::flat_hash_map<std::string, int> result;
    std::vector<std::string> lines = absl::StrSplit(csv_data, '\n');

    for (const auto& line : lines) {
      if (line.empty()) continue;

      std::vector<std::string> parts = absl::StrSplit(line, ',');
      if (parts.size() >= 2) {
        std::string key = std::string(absl::StripAsciiWhitespace(parts[0]));
        int value =
            std::stoi(std::string(absl::StripAsciiWhitespace(parts[1])));
        result[key] += value;
      }
    }

    // Log completion
    auto log_completion_status = logger_->Log(
        "INFO", absl::StrFormat("Processed %d unique keys", result.size()));
    if (!log_completion_status.ok()) {
      return log_completion_status;
    }

    return result;
  }

  absl::Status ProcessWithTimeout(absl::string_view data,
                                  absl::Duration timeout) {
    absl::Time start = absl::Now();
    logger_->SetTimestamp(start);

    // Simulate some processing time
    auto processing_result = ProcessCsvData(data);

    absl::Time end = absl::Now();
    absl::Duration elapsed = end - start;

    if (elapsed > timeout) {
      return absl::DeadlineExceededError(absl::StrFormat(
          "Processing took %s, exceeded timeout of %s",
          absl::FormatDuration(elapsed), absl::FormatDuration(timeout)));
    }

    if (!processing_result.ok()) {
      return processing_result.status();
    }

    return absl::OkStatus();
  }

  absl::flat_hash_set<std::string> GetUniqueKeys(
      const absl::flat_hash_map<std::string, int>& data) {
    absl::flat_hash_set<std::string> keys;
    for (const auto& [key, value] : data) {
      keys.insert(key);
    }
    return keys;
  }

 private:
  std::unique_ptr<MockLogger> logger_;
};

// Test fixture combining Abseil and GTest/GMock
class CombinedIntegrationTest : public ::testing::Test {
 protected:
  void SetUp() override {
    mock_logger_ = std::make_unique<MockLoggerImpl>();
    raw_mock_logger_ = mock_logger_.get();
    service_ = std::make_unique<DataProcessingService>(std::move(mock_logger_));
  }

  void TearDown() override {
    service_.reset();
    raw_mock_logger_ = nullptr;
  }

  std::unique_ptr<MockLoggerImpl> mock_logger_;
  MockLoggerImpl* raw_mock_logger_;
  std::unique_ptr<DataProcessingService> service_;
};

// Test successful data processing with Abseil containers and GTest matchers
TEST_F(CombinedIntegrationTest, SuccessfulDataProcessing) {
  // Set up mock expectations
  EXPECT_CALL(*raw_mock_logger_,
              Log(Eq("INFO"), HasSubstr("Processing CSV data of size")))
      .WillOnce(Return(absl::OkStatus()));

  EXPECT_CALL(*raw_mock_logger_,
              Log(Eq("INFO"), HasSubstr("Processed 3 unique keys")))
      .WillOnce(Return(absl::OkStatus()));

  // Test data
  absl::string_view csv_data = "apple,10\nbanana,20\napple,5\norange,15";

  // Process the data
  auto result = service_->ProcessCsvData(csv_data);

  // Verify the result using GTest assertions
  ASSERT_TRUE(result.ok()) << "Processing should succeed: " << result.status();

  const auto& data = result.value();
  EXPECT_EQ(data.size(), 3);
  EXPECT_EQ(data.at("apple"), 15);  // 10 + 5
  EXPECT_EQ(data.at("banana"), 20);
  EXPECT_EQ(data.at("orange"), 15);

  // Test unique keys extraction
  auto unique_keys = service_->GetUniqueKeys(data);
  EXPECT_EQ(unique_keys.size(), 3);
  EXPECT_TRUE(unique_keys.contains("apple"));
  EXPECT_TRUE(unique_keys.contains("banana"));
  EXPECT_TRUE(unique_keys.contains("orange"));
}

// Test error handling with Abseil Status and GTest
TEST_F(CombinedIntegrationTest, ErrorHandling) {
  // Test empty data error
  auto result = service_->ProcessCsvData("");
  EXPECT_FALSE(result.ok());
  EXPECT_EQ(result.status().code(), absl::StatusCode::kInvalidArgument);
  EXPECT_THAT(result.status().message(), HasSubstr("CSV data cannot be empty"));

  // Test logger error propagation
  EXPECT_CALL(*raw_mock_logger_, Log(_, _))
      .WillOnce(Return(absl::InternalError("Logger failed")));

  result = service_->ProcessCsvData("test,1");
  EXPECT_FALSE(result.ok());
  EXPECT_EQ(result.status().code(), absl::StatusCode::kInternal);
  EXPECT_THAT(result.status().message(), HasSubstr("Logger failed"));
}

// Test timeout functionality with Abseil Time and GMock
TEST_F(CombinedIntegrationTest, TimeoutHandling) {
  // Set up mock to accept timestamp setting
  EXPECT_CALL(*raw_mock_logger_, SetTimestamp(_)).Times(1);

  // Set up mock to handle logging
  EXPECT_CALL(*raw_mock_logger_, Log(_, _))
      .WillRepeatedly(Return(absl::OkStatus()));

  // Test with very short timeout (should not timeout for small data)
  absl::string_view small_data = "key,1";
  absl::Duration short_timeout = absl::Milliseconds(100);

  auto status = service_->ProcessWithTimeout(small_data, short_timeout);
  EXPECT_TRUE(status.ok()) << "Small data should process within timeout: "
                           << status;
}

// Test Abseil string operations with GTest matchers
TEST_F(CombinedIntegrationTest, AbseilStringOperations) {
  // Test string formatting with StrFormat
  std::string formatted =
      absl::StrFormat("User: %s, Score: %d, Time: %s", "Alice", 95,
                      absl::FormatTime(absl::Now()));

  EXPECT_THAT(formatted, HasSubstr("User: Alice"));
  EXPECT_THAT(formatted, HasSubstr("Score: 95"));
  EXPECT_THAT(formatted, HasSubstr("Time:"));

  // Test string splitting and joining
  absl::string_view data = "red,green,blue,yellow";
  std::vector<std::string> colors = absl::StrSplit(data, ',');

  EXPECT_THAT(colors, ElementsAre("red", "green", "blue", "yellow"));

  std::string rejoined = absl::StrJoin(colors, "|");
  EXPECT_EQ(rejoined, "red|green|blue|yellow");
}

// Test Abseil containers with complex data
TEST_F(CombinedIntegrationTest, ComplexDataStructures) {
  // Create nested data structure using Abseil containers
  absl::flat_hash_map<std::string, absl::flat_hash_set<int>> category_values;

  category_values["prime"].insert({2, 3, 5, 7, 11});
  category_values["even"].insert({2, 4, 6, 8, 10});
  category_values["odd"].insert({1, 3, 5, 7, 9, 11});

  // Test container properties
  EXPECT_EQ(category_values.size(), 3);
  EXPECT_EQ(category_values["prime"].size(), 5);
  EXPECT_EQ(category_values["even"].size(), 5);
  EXPECT_EQ(category_values["odd"].size(), 6);

  // Test overlapping values
  absl::flat_hash_set<int> prime_and_odd;
  for (int value : category_values["prime"]) {
    if (category_values["odd"].contains(value)) {
      prime_and_odd.insert(value);
    }
  }

  EXPECT_THAT(std::vector<int>(prime_and_odd.begin(), prime_and_odd.end()),
              ::testing::UnorderedElementsAre(3, 5, 7, 11));
}

// Test status chains and error propagation
TEST_F(CombinedIntegrationTest, StatusChaining) {
  auto create_error_status = [](const std::string& msg) -> absl::Status {
    return absl::InvalidArgumentError(msg);
  };

  auto chain_status = [&](absl::Status base_status) -> absl::Status {
    if (!base_status.ok()) {
      return absl::InternalError(
          absl::StrCat("Chained error: ", base_status.message()));
    }
    return absl::OkStatus();
  };

  // Test error chaining
  absl::Status original = create_error_status("Original error");
  absl::Status chained = chain_status(original);

  EXPECT_FALSE(chained.ok());
  EXPECT_EQ(chained.code(), absl::StatusCode::kInternal);
  EXPECT_THAT(chained.message(), HasSubstr("Chained error"));
  EXPECT_THAT(chained.message(), HasSubstr("Original error"));
}

// Performance test combining both libraries
TEST_F(CombinedIntegrationTest, PerformanceTest) {
  const int iterations = 1000;

  // Set up mock to handle many calls efficiently
  EXPECT_CALL(*raw_mock_logger_, Log(_, _))
      .Times(iterations * 2)  // Start and end logging for each iteration
      .WillRepeatedly(Return(absl::OkStatus()));

  auto start = absl::Now();

  for (int i = 0; i < iterations; ++i) {
    std::string test_data = absl::StrFormat("item_%d,%d", i, i * 2);
    auto result = service_->ProcessCsvData(test_data);
    ASSERT_TRUE(result.ok());
    ASSERT_EQ(result.value().size(), 1);
  }

  absl::Duration elapsed = absl::Now() - start;

  // Should complete in reasonable time
  EXPECT_LT(absl::ToDoubleSeconds(elapsed), 1.0);

  std::cout << "Processed " << iterations << " items in "
            << absl::FormatDuration(elapsed) << std::endl;
}

// Integration test with real-world scenario
TEST_F(CombinedIntegrationTest, RealWorldScenario) {
  // Set up expectations for a complete workflow
  EXPECT_CALL(*raw_mock_logger_, Log(Eq("INFO"), _))
      .Times(::testing::AtLeast(2))
      .WillRepeatedly(Return(absl::OkStatus()));

  EXPECT_CALL(*raw_mock_logger_, GetLastLog())
      .WillOnce(Return(absl::StatusOr<std::string>("Last log message")));

  // Simulate processing sales data
  absl::string_view sales_data =
      "ProductA,100\n"
      "ProductB,200\n"
      "ProductA,50\n"
      "ProductC,300\n"
      "ProductB,150\n";

  // Process the sales data
  auto result = service_->ProcessCsvData(sales_data);
  ASSERT_TRUE(result.ok());

  const auto& sales_totals = result.value();

  // Verify business logic
  EXPECT_EQ(sales_totals.at("ProductA"), 150);  // 100 + 50
  EXPECT_EQ(sales_totals.at("ProductB"), 350);  // 200 + 150
  EXPECT_EQ(sales_totals.at("ProductC"), 300);

  // Find top-selling product
  std::string top_product;
  int max_sales = 0;
  for (const auto& [product, sales] : sales_totals) {
    if (sales > max_sales) {
      max_sales = sales;
      top_product = product;
    }
  }

  EXPECT_EQ(top_product, "ProductB");
  EXPECT_EQ(max_sales, 350);

  // Generate summary report
  std::string summary = absl::StrFormat(
      "Sales Summary: %d products, top seller: %s (%d units), total: %d units",
      sales_totals.size(), top_product, max_sales,
      std::accumulate(
          sales_totals.begin(), sales_totals.end(), 0,
          [](int sum, const auto& pair) { return sum + pair.second; }));

  EXPECT_THAT(summary, HasSubstr("Sales Summary: 3 products"));
  EXPECT_THAT(summary, HasSubstr("top seller: ProductB"));
  EXPECT_THAT(summary, HasSubstr("total: 800 units"));

  // Verify logger state
  auto last_log = raw_mock_logger_->GetLastLog();
  ASSERT_TRUE(last_log.ok());
  EXPECT_EQ(last_log.value(), "Last log message");
}

int main(int argc, char** argv) {
  ::testing::InitGoogleTest(&argc, argv);

  std::cout << "Testing combined Abseil + GTest/GMock integration..."
            << std::endl;
  std::cout << "Current time: " << absl::FormatTime(absl::Now()) << std::endl;

  return RUN_ALL_TESTS();
}
