#include <absl/container/flat_hash_map.h>
#include <absl/container/flat_hash_set.h>
#include <absl/hash/hash.h>
#include <absl/numeric/int128.h>
#include <absl/status/status.h>
#include <absl/status/statusor.h>
#include <absl/strings/str_cat.h>
#include <absl/strings/str_format.h>
#include <absl/strings/str_split.h>
#include <absl/strings/string_view.h>
#include <absl/time/clock.h>
#include <absl/time/time.h>
#include <gtest/gtest.h>

#include <cstdint>
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
  absl::string_view sv_original(original);
  EXPECT_EQ(sv_original.size(), 14);
  EXPECT_EQ(sv_original, "Hello, Abseil!");

  // Test str_cat
  std::string result = absl::StrCat("Hello", ", ", "World", "!");
  EXPECT_EQ(result, "Hello, World!");

  // Test str_format
  absl::ParsedFormat<'d', 's'> format_template("Number: %d, String: %s");
  std::string formatted = absl::StrFormat(format_template, 42, "test");
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

// absl::uint128 construction, bit access, hashing, and containers
TEST_F(AbseilIntegrationTest, Uint128BasicAndHash) {
  constexpr uint64_t HIGH_WORD = 0x0123456789ABCDEFULL;
  constexpr uint64_t LOW_WORD = 0x0FEDCBA987654321ULL;

  // Construct and verify high/low 64-bit halves
  absl::uint128 vu1 = absl::MakeUint128(HIGH_WORD, LOW_WORD);
  EXPECT_EQ(absl::Uint128High64(vu1), HIGH_WORD);
  EXPECT_EQ(absl::Uint128Low64(vu1), LOW_WORD);

  // Hash stability and difference across values
  absl::Hash<absl::uint128> hu1;
  size_t hv1 = hu1(vu1);
  size_t hv2 = hu1(vu1);
  EXPECT_EQ(hv1, hv2);

  // Change one bit in the low part to ensure hash changes
  absl::uint128 uv2 = absl::MakeUint128(HIGH_WORD, LOW_WORD ^ 0x1ULL);
  EXPECT_NE(hu1(uv2), hv1);

  // Use as key in flat_hash_map
  absl::flat_hash_map<absl::uint128, int> afhm_u1_int;
  afhm_u1_int[vu1] = 42;
  afhm_u1_int[uv2] = 7;
  EXPECT_EQ(afhm_u1_int.at(vu1), 42);
  EXPECT_EQ(afhm_u1_int.at(uv2), 7);

  // Ordering and arithmetic sanity
  absl::uint128 uv3 = vu1 + absl::uint128(1);
  EXPECT_LT(vu1, uv3);
}

// Performance test to ensure the libraries are working efficiently
TEST_F(AbseilIntegrationTest, PerformanceTest) {
  const int ITERATIONS = 10000;

  // Test string concatenation performance
  auto start = absl::Now();
  std::string result;
  for (int i = 0; i < ITERATIONS; ++i) {
    result = absl::StrCat("prefix_", i, "_suffix");
  }
  auto duration = absl::Now() - start;

  // Should complete in reasonable time (less than 1 second)
  EXPECT_LT(absl::ToDoubleSeconds(duration), 1.0);

  // Test container performance
  start = absl::Now();
  absl::flat_hash_map<int, std::string> perf_map;
  for (int i = 0; i < ITERATIONS; ++i) {
    perf_map[i] = absl::StrCat("value_", i);
  }
  duration = absl::Now() - start;

  EXPECT_EQ(perf_map.size(), ITERATIONS);
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
  absl::ParsedFormat<'d', 'd', 'd'> summary_format(
      "Processed %d entries, found %d unique fruits. Apple total: %d");
  std::string summary = absl::StrFormat(summary_format, entries.size(),
                                        totals.size(), totals["apple"]);

  EXPECT_FALSE(summary.empty());
  EXPECT_TRUE(absl::StrContains(summary, "Apple total: 15"));
}

int main(int argc, char** argv) {
  ::testing::InitGoogleTest(&argc, argv);

  // Print version information
  std::cout << "Testing Abseil integration...\n";
  std::cout << "Current time: " << absl::FormatTime(absl::Now()) << '\n';

  return RUN_ALL_TESTS();
}
