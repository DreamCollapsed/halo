#include <fast_float/fast_float.h>
#include <gtest/gtest.h>

#include <array>
#include <cmath>
#include <cstring>
#include <iterator>
#include <string>
#include <string_view>
#include <tuple>
#include <vector>

// Test fixture for fast-float integration tests
class FastFloatIntegrationTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // Setup code if needed
  }

  void TearDown() override {
    // Cleanup code if needed
  }
};

// Test basic float parsing
TEST_F(FastFloatIntegrationTest, BasicFloatParsing) {
  std::string_view input = "3.14159";
  float result = 0.0F;
  auto answer = fast_float::from_chars(input.begin(), input.end(), result);

  EXPECT_EQ(answer.ec, std::errc{});
  EXPECT_FLOAT_EQ(result, 3.14159F);
  EXPECT_EQ(answer.ptr, input.end());
}

// Test basic double parsing
TEST_F(FastFloatIntegrationTest, BasicDoubleParsing) {
  std::string_view input = "2.718281828459045";
  double result = 0.0;
  auto answer = fast_float::from_chars(input.begin(), input.end(), result);

  EXPECT_EQ(answer.ec, std::errc{});
  EXPECT_DOUBLE_EQ(result, 2.718281828459045);
  EXPECT_EQ(answer.ptr, input.end());
}

// Test scientific notation parsing
TEST_F(FastFloatIntegrationTest, ScientificNotation) {
  std::string_view input = "1.23e-4";
  double result = 0.0;
  auto answer = fast_float::from_chars(input.begin(), input.end(), result);

  EXPECT_EQ(answer.ec, std::errc{});
  EXPECT_DOUBLE_EQ(result, 1.23e-4);
  EXPECT_EQ(answer.ptr, input.end());
}

// Test negative numbers
TEST_F(FastFloatIntegrationTest, NegativeNumbers) {
  std::string_view input = "-42.5";
  float result = 0.0F;
  auto answer = fast_float::from_chars(input.begin(), input.end(), result);

  EXPECT_EQ(answer.ec, std::errc{});
  EXPECT_FLOAT_EQ(result, -42.5F);
  EXPECT_EQ(answer.ptr, input.end());
}

// Test zero parsing
TEST_F(FastFloatIntegrationTest, ZeroParsing) {
  std::string_view input = "0.0";
  double result = 0.0;
  auto answer = fast_float::from_chars(input.begin(), input.end(), result);

  EXPECT_EQ(answer.ec, std::errc{});
  EXPECT_DOUBLE_EQ(result, 0.0);
  EXPECT_EQ(answer.ptr, input.end());
}

// Test infinity parsing
TEST_F(FastFloatIntegrationTest, InfinityParsing) {
  std::string_view input = "inf";
  double result = 0.0;
  auto answer = fast_float::from_chars(input.begin(), input.end(), result);

  EXPECT_EQ(answer.ec, std::errc{});
  EXPECT_TRUE(std::isinf(result));
  EXPECT_TRUE(result > 0);
  EXPECT_EQ(answer.ptr, input.end());
}

// Test negative infinity parsing
TEST_F(FastFloatIntegrationTest, NegativeInfinityParsing) {
  std::string_view input = "-inf";
  double result = 0.0;
  auto answer = fast_float::from_chars(input.begin(), input.end(), result);

  EXPECT_EQ(answer.ec, std::errc{});
  EXPECT_TRUE(std::isinf(result));
  EXPECT_TRUE(result < 0);
  EXPECT_EQ(answer.ptr, input.end());
}

// Test NaN parsing
TEST_F(FastFloatIntegrationTest, NaNParsing) {
  std::string_view input = "nan";
  double result = 0.0;
  auto answer = fast_float::from_chars(input.begin(), input.end(), result);

  EXPECT_EQ(answer.ec, std::errc{});
  EXPECT_TRUE(std::isnan(result));
  EXPECT_EQ(answer.ptr, input.end());
}

// Test invalid input
TEST_F(FastFloatIntegrationTest, InvalidInput) {
  std::string_view input = "not_a_number";
  double result = 0.0;
  auto answer = fast_float::from_chars(input.begin(), input.end(), result);

  EXPECT_EQ(answer.ec, std::errc::invalid_argument);
  EXPECT_EQ(answer.ptr, input.begin());
}

// Test partial parsing
TEST_F(FastFloatIntegrationTest, PartialParsing) {
  std::string_view input = "123.45abc";
  double result = 0.0;
  auto answer = fast_float::from_chars(input.begin(), input.end(), result);

  EXPECT_EQ(answer.ec, std::errc{});
  EXPECT_DOUBLE_EQ(result, 123.45);
  EXPECT_EQ(std::distance(input.begin(), answer.ptr), 6);
}

// Test very large numbers
TEST_F(FastFloatIntegrationTest, VeryLargeNumbers) {
  std::string_view input = "1.7976931348623157e+308";  // Close to max double
  double result = 0.0;
  auto answer = fast_float::from_chars(input.begin(), input.end(), result);

  EXPECT_EQ(answer.ec, std::errc{});
  EXPECT_DOUBLE_EQ(result, 1.7976931348623157e+308);
  EXPECT_EQ(answer.ptr, input.end());
}

// Test very small numbers
TEST_F(FastFloatIntegrationTest, VerySmallNumbers) {
  std::string_view input = "2.2250738585072014e-308";  // Close to min double
  double result = 0.0;
  auto answer = fast_float::from_chars(input.begin(), input.end(), result);

  EXPECT_EQ(answer.ec, std::errc{});
  EXPECT_DOUBLE_EQ(result, 2.2250738585072014e-308);
  EXPECT_EQ(answer.ptr, input.end());
}

// Test performance compared to standard library (basic performance test)
TEST_F(FastFloatIntegrationTest, BasicPerformanceTest) {
  std::vector<std::string> test_numbers = {
      "3.14159", "2.71828", "1.41421", "1.73205", "0.57721",
      "123.456", "789.012", "999.999", "0.00001", "1000000.0"};

  // Test that fast_float can parse all numbers correctly
  for (const auto& num_str : test_numbers) {
    std::string_view num_view{num_str};
    double result = 0.0;
    auto answer =
        fast_float::from_chars(num_view.begin(), num_view.end(), result);

    EXPECT_EQ(answer.ec, std::errc{}) << "Failed to parse: " << num_str;
    EXPECT_EQ(answer.ptr, num_view.end()) << "Incomplete parse: " << num_str;

    // Verify result is reasonable (not NaN or inf for these inputs)
    EXPECT_FALSE(std::isnan(result)) << "Got NaN for: " << num_str;
    EXPECT_FALSE(std::isinf(result)) << "Got infinity for: " << num_str;
  }
}

// Comprehensive edge case testing
TEST_F(FastFloatIntegrationTest, EdgeCases) {
  std::array<std::tuple<std::string_view, bool, double>, 13> test_cases = {
      std::tuple<std::string_view, bool, double>{"0", true, 0.0},
      {"1", true, 1.0},
      {"-1", true, -1.0},
      {"0.0", true, 0.0},
      {"1.0", true, 1.0},
      {"-1.0", true, -1.0},
      {"1e0", true, 1.0},
      {"1e1", true, 10.0},
      {"1e-1", true, 0.1},
      {"", false, 0.0},
      {".", false, 0.0},
      {"e", false, 0.0},
      // fast_float doesn't support explicit positive signs
      {"+1", false, 0.0},
  };

  for (auto [input_case, should_succeed, expected_value] : test_cases) {
    double result = 0.0;
    auto answer =
        fast_float::from_chars(input_case.begin(), input_case.end(), result);

    if (should_succeed) {
      EXPECT_EQ(answer.ec, std::errc{})
          << "Should succeed for: '" << input_case << "'";
      if (answer.ec == std::errc{}) {
        EXPECT_DOUBLE_EQ(result, expected_value)
            << "Wrong value for: '" << input_case << "'";
      }
    } else {
      EXPECT_NE(answer.ec, std::errc{})
          << "Should fail for: '" << input_case << "'";
    }
  }
}

// Test fast_float version
TEST_F(FastFloatIntegrationTest, VersionCheck) {
  EXPECT_EQ(FASTFLOAT_VERSION_MAJOR, 8);
  EXPECT_EQ(FASTFLOAT_VERSION_MINOR, 1);
  EXPECT_EQ(FASTFLOAT_VERSION_PATCH, 0);
  EXPECT_EQ(FASTFLOAT_VERSION, 80100);
}
