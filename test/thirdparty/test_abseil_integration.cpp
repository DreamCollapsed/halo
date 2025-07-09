#include <absl/container/flat_hash_map.h>
#include <absl/container/flat_hash_set.h>
#include <absl/hash/hash.h>
#include <absl/status/status.h>
#include <absl/status/statusor.h>
#include <absl/strings/str_cat.h>
#include <absl/strings/str_format.h>
#include <absl/strings/str_split.h>
#include <absl/strings/string_view.h>
#include <absl/time/clock.h>
#include <absl/time/time.h>
#include <gtest/gtest.h>

#include <string>
#include <vector>

// Test fixture for Abseil integration tests
class AbseilIntegrationTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // Setup code if needed
  }

  void TearDown() override {
    // Cleanup code if needed
  }
};

// Test basic string operations
TEST_F(AbseilIntegrationTest, StringOperations) {
  // Test string_view
  std::string original = "Hello, Abseil!";
  absl::string_view sv(original);
  EXPECT_EQ(sv.size(), 14);
  EXPECT_EQ(sv, "Hello, Abseil!");

  // Test str_cat
  std::string result = absl::StrCat("Hello", ", ", "World", "!");
  EXPECT_EQ(result, "Hello, World!");

  // Test str_format
  std::string formatted = absl::StrFormat("Number: %d, String: %s", 42, "test");
  EXPECT_EQ(formatted, "Number: 42, String: test");

  // Test str_split
  std::string data = "apple,banana,orange";
  std::vector<std::string> fruits = absl::StrSplit(data, ',');
  ASSERT_EQ(fruits.size(), 3);
  EXPECT_EQ(fruits[0], "apple");
  EXPECT_EQ(fruits[1], "banana");
  EXPECT_EQ(fruits[2], "orange");
}

// Test container operations
TEST_F(AbseilIntegrationTest, ContainerOperations) {
  // Test flat_hash_map
  absl::flat_hash_map<std::string, int> word_count;
  word_count["hello"] = 1;
  word_count["world"] = 2;
  word_count["abseil"] = 3;

  EXPECT_EQ(word_count.size(), 3);
  EXPECT_EQ(word_count["hello"], 1);
  EXPECT_EQ(word_count["world"], 2);
  EXPECT_EQ(word_count["abseil"], 3);

  // Test flat_hash_set
  absl::flat_hash_set<std::string> unique_words;
  unique_words.insert("hello");
  unique_words.insert("world");
  unique_words.insert("hello");  // Duplicate

  EXPECT_EQ(unique_words.size(), 2);
  EXPECT_TRUE(unique_words.contains("hello"));
  EXPECT_TRUE(unique_words.contains("world"));
  EXPECT_FALSE(unique_words.contains("abseil"));
}

// Test time operations
TEST_F(AbseilIntegrationTest, TimeOperations) {
  // Test time creation
  absl::Time epoch = absl::UnixEpoch();
  absl::Time now = absl::Now();

  EXPECT_GT(now, epoch);

  // Test duration
  absl::Duration five_seconds = absl::Seconds(5);
  absl::Duration five_minutes = absl::Minutes(5);

  EXPECT_EQ(absl::ToDoubleSeconds(five_seconds), 5.0);
  EXPECT_EQ(absl::ToDoubleMinutes(five_minutes), 5.0);

  // Test time arithmetic
  absl::Time future = now + five_seconds;
  EXPECT_GT(future, now);
  EXPECT_EQ(future - now, five_seconds);
}

// Test status operations
TEST_F(AbseilIntegrationTest, StatusOperations) {
  // Test OK status
  absl::Status ok_status = absl::OkStatus();
  EXPECT_TRUE(ok_status.ok());
  EXPECT_EQ(ok_status.code(), absl::StatusCode::kOk);

  // Test error status
  absl::Status error_status = absl::InvalidArgumentError("Invalid input");
  EXPECT_FALSE(error_status.ok());
  EXPECT_EQ(error_status.code(), absl::StatusCode::kInvalidArgument);
  EXPECT_EQ(error_status.message(), "Invalid input");

  // Test StatusOr with success
  absl::StatusOr<int> success_result(42);
  EXPECT_TRUE(success_result.ok());
  EXPECT_EQ(*success_result, 42);
  EXPECT_EQ(success_result.value(), 42);

  // Test StatusOr with error
  absl::StatusOr<int> error_result = absl::InvalidArgumentError("Bad number");
  EXPECT_FALSE(error_result.ok());
  EXPECT_EQ(error_result.status().code(), absl::StatusCode::kInvalidArgument);
}

// Test hash operations
TEST_F(AbseilIntegrationTest, HashOperations) {
  // Test basic hash
  absl::Hash<std::string> string_hasher;
  size_t hash1 = string_hasher("hello");
  size_t hash2 = string_hasher("hello");
  size_t hash3 = string_hasher("world");

  EXPECT_EQ(hash1, hash2);  // Same input should have same hash
  EXPECT_NE(hash1, hash3);  // Different input should have different hash

  // Test hash with containers
  absl::flat_hash_map<std::string, int> hash_map;
  hash_map["key1"] = 100;
  hash_map["key2"] = 200;

  EXPECT_TRUE(hash_map.contains("key1"));
  EXPECT_FALSE(hash_map.contains("key3"));
}

// Performance test to ensure the libraries are working efficiently
TEST_F(AbseilIntegrationTest, PerformanceTest) {
  const int iterations = 10000;

  // Test string concatenation performance
  auto start = absl::Now();
  std::string result;
  for (int i = 0; i < iterations; ++i) {
    result = absl::StrCat("prefix_", i, "_suffix");
  }
  auto duration = absl::Now() - start;

  // Should complete in reasonable time (less than 1 second)
  EXPECT_LT(absl::ToDoubleSeconds(duration), 1.0);

  // Test container performance
  start = absl::Now();
  absl::flat_hash_map<int, std::string> perf_map;
  for (int i = 0; i < iterations; ++i) {
    perf_map[i] = absl::StrCat("value_", i);
  }
  duration = absl::Now() - start;

  EXPECT_EQ(perf_map.size(), iterations);
  EXPECT_LT(absl::ToDoubleSeconds(duration), 1.0);
}

// Integration test combining multiple Abseil features
TEST_F(AbseilIntegrationTest, IntegrationTest) {
  // Create a data processing pipeline using multiple Abseil components
  std::string input_data = "apple:10,banana:20,orange:15,apple:5";

  // Parse the data
  std::vector<std::string> entries = absl::StrSplit(input_data, ',');
  absl::flat_hash_map<std::string, int> totals;

  for (const auto& entry : entries) {
    std::vector<std::string> parts = absl::StrSplit(entry, ':');
    if (parts.size() == 2) {
      std::string fruit = std::string(parts[0]);
      int value = std::stoi(std::string(parts[1]));
      totals[fruit] += value;
    }
  }

  // Verify results
  EXPECT_EQ(totals.size(), 3);
  EXPECT_EQ(totals["apple"], 15);  // 10 + 5
  EXPECT_EQ(totals["banana"], 20);
  EXPECT_EQ(totals["orange"], 15);

  // Format results using str_format
  std::string summary = absl::StrFormat(
      "Processed %d entries, found %d unique fruits. Apple total: %d",
      entries.size(), totals.size(), totals["apple"]);

  EXPECT_FALSE(summary.empty());
  EXPECT_TRUE(absl::StrContains(summary, "Apple total: 15"));
}

int main(int argc, char** argv) {
  ::testing::InitGoogleTest(&argc, argv);

  // Print version information
  std::cout << "Testing Abseil integration..." << std::endl;
  std::cout << "Current time: " << absl::FormatTime(absl::Now()) << std::endl;

  return RUN_ALL_TESTS();
}
