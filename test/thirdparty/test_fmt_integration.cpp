#include <fmt/chrono.h>
#include <fmt/core.h>
#include <fmt/format.h>
#include <fmt/ranges.h>
#include <gtest/gtest.h>

#include <chrono>
#include <ctime>
#include <map>
#include <string>
#include <string_view>
#include <vector>

// Test fixture for fmt integration tests
class FmtIntegrationTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // Setup code if needed
  }

  void TearDown() override {
    // Cleanup code if needed
  }
};

// Test basic string formatting
TEST_F(FmtIntegrationTest, BasicFormatting) {
  std::string result = fmt::format("Hello, {}!", "World");
  EXPECT_EQ(result, "Hello, World!");

  result = fmt::format("Number: {}", 42);
  EXPECT_EQ(result, "Number: 42");

  result = fmt::format("Float: {:.2f}",
                       3.14159);  // NOLINT(modernize-use-std-numbers)
  EXPECT_EQ(result, "Float: 3.14");
}

// Test positional arguments
TEST_F(FmtIntegrationTest, PositionalArguments) {
  std::string result = fmt::format("{1} {0}", "World", "Hello");
  EXPECT_EQ(result, "Hello World");

  result = fmt::format("{0} {2} {1}", "The", "brown", "quick");
  EXPECT_EQ(result, "The quick brown");
}

// Test named arguments
TEST_F(FmtIntegrationTest, NamedArguments) {
  using fmt::literals::operator""_a;

  std::string result = fmt::format("Hello, {name}! You are {age} years old.",
                                   "name"_a = "Alice", "age"_a = 30);
  EXPECT_EQ(result, "Hello, Alice! You are 30 years old.");
}

// Test number formatting
TEST_F(FmtIntegrationTest, NumberFormatting) {
  // Integer formatting
  EXPECT_EQ(fmt::format("{:d}", 42), "42");
  EXPECT_EQ(fmt::format("{:x}", 255), "ff");
  EXPECT_EQ(fmt::format("{:X}", 255), "FF");
  EXPECT_EQ(fmt::format("{:o}", 64), "100");
  EXPECT_EQ(fmt::format("{:b}", 10), "1010");

  // Floating point formatting
  EXPECT_EQ(fmt::format("{:.2f}", 3.14159), "3.14");
  EXPECT_EQ(fmt::format("{:.0f}", 3.14159), "3");
  EXPECT_EQ(fmt::format("{:e}", 1234.5), "1.234500e+03");
  EXPECT_EQ(fmt::format("{:E}", 1234.5), "1.234500E+03");
}

// Test alignment and padding
TEST_F(FmtIntegrationTest, AlignmentAndPadding) {
  EXPECT_EQ(fmt::format("{:>10}", "test"), "      test");
  EXPECT_EQ(fmt::format("{:<10}", "test"), "test      ");
  EXPECT_EQ(fmt::format("{:^10}", "test"), "   test   ");
  EXPECT_EQ(fmt::format("{:*^10}", "test"), "***test***");
  EXPECT_EQ(fmt::format("{:05d}", 42), "00042");
}

// Test containers formatting (ranges)
TEST_F(FmtIntegrationTest, ContainerFormatting) {
  std::vector<int> numbers = {1, 2, 3, 4, 5};
  std::string result = fmt::format("{}", numbers);
  EXPECT_EQ(result, "[1, 2, 3, 4, 5]");

  std::map<std::string, int> scores = {{"Alice", 95}, {"Bob", 87}};
  result = fmt::format("{}", scores);
  // Note: map order might vary, so we just check it's formatted correctly
  EXPECT_NE(result.find("Alice"), std::string::npos);
  EXPECT_NE(result.find("Bob"), std::string::npos);
  EXPECT_NE(result.find("95"), std::string::npos);
  EXPECT_NE(result.find("87"), std::string::npos);
}

// Test time formatting
TEST_F(FmtIntegrationTest, TimeFormatting) {
  auto now = std::chrono::system_clock::now();
  auto time_value = std::chrono::system_clock::to_time_t(now);
  std::tm time_info{};
#ifdef _WIN32
  localtime_s(&time_info, &time_value);
#else
  localtime_r(&time_value, &time_info);
#endif

  // Test basic time formatting
  std::string result = fmt::format("{:%Y-%m-%d}", time_info);
  EXPECT_EQ(result.length(), 10);  // YYYY-MM-DD format
  EXPECT_EQ(result[4], '-');
  EXPECT_EQ(result[7], '-');

  result = fmt::format("{:%H:%M:%S}", time_info);
  EXPECT_EQ(result.length(), 8);  // HH:MM:SS format
  EXPECT_EQ(result[2], ':');
  EXPECT_EQ(result[5], ':');
}

// Test duration formatting
TEST_F(FmtIntegrationTest, DurationFormatting) {
  auto duration = std::chrono::milliseconds(1500);
  std::string result = fmt::format("{}", duration);
  EXPECT_TRUE(result.find("1500") != std::string::npos);
  EXPECT_TRUE(result.find("ms") != std::string::npos);

  auto seconds = std::chrono::seconds(30);
  result = fmt::format("{}", seconds);
  EXPECT_TRUE(result.find("30") != std::string::npos);
  EXPECT_NE(result.find('s'), std::string::npos);
}

// Test custom types (user-defined types)
struct Point {
  double x_coord_{0.0};
  double y_coord_{0.0};
};

TEST_F(FmtIntegrationTest, CustomTypeFormatting) {
  Point point{.x_coord_ = 3.14, .y_coord_ = 2.71};
  std::string result =
      fmt::format("({:.1f}, {:.1f})", point.x_coord_, point.y_coord_);
  EXPECT_EQ(result, "(3.1, 2.7)");
}

// Test error handling
TEST_F(FmtIntegrationTest, ErrorHandling) {
  // Test format string validation at compile time
  // These should compile without issues
  EXPECT_NO_THROW({
    std::string result = fmt::format("{}", 42);
    EXPECT_EQ(result, "42");
  });

  EXPECT_NO_THROW({
    std::string result = fmt::format("{:d}", 42);
    EXPECT_EQ(result, "42");
  });
}

// Test performance characteristics
TEST_F(FmtIntegrationTest, PerformanceBasics) {
  // Test that fmt formatting works correctly for large strings
  // Use left-aligned padding to ensure "test" is at the beginning
  std::string large_format = fmt::format("{:<1000}", "test");
  EXPECT_EQ(large_format.length(), 1000);
  // With left alignment, "test" should be at the beginning, followed by spaces
  EXPECT_TRUE(large_format.substr(0, 4) == "test");
  EXPECT_TRUE(large_format.substr(4, 4) ==
              "    ");  // Check for spaces after "test"

  // Test formatting many numbers
  std::vector<std::string> results;
  results.reserve(1000);
  for (int i = 0; i < 1000; ++i) {
    results.push_back(fmt::format("Number: {}", i));
  }
  EXPECT_EQ(results.size(), 1000);
  EXPECT_EQ(results[0], "Number: 0");
  EXPECT_EQ(results[999], "Number: 999");
}

// Test fmt::print functionality
TEST_F(FmtIntegrationTest, PrintFunctionality) {
  // Since we can't easily capture stdout in this test,
  // we'll test that the print function doesn't throw
  EXPECT_NO_THROW({ fmt::print("Testing fmt::print with number: {}\n", 42); });
}

// Test memory safety and RAII
TEST_F(FmtIntegrationTest, MemorySafety) {
  // Test with string_view
  std::string original = "Hello, World!";
  std::string_view view = original;
  std::string result = fmt::format("Message: {}", view);
  EXPECT_EQ(result, "Message: Hello, World!");

  // Test with temporary objects
  result = fmt::format("{}", std::string("Temporary"));
  EXPECT_EQ(result, "Temporary");
}

// Test locale independence
TEST_F(FmtIntegrationTest, LocaleIndependence) {
  // fmt should produce consistent output regardless of locale
  double value = 1234.56;
  std::string result = fmt::format("{:.2f}", value);
  EXPECT_EQ(result, "1234.56");  // Always uses '.' as decimal separator
}
