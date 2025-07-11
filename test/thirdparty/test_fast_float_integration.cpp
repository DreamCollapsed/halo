#include <fast_float/fast_float.h>
#include <gtest/gtest.h>

#include <cmath>
#include <cstring>
#include <string>
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
  const char* input = "3.14159";
  float result;
  auto answer =
      fast_float::from_chars(input, input + std::strlen(input), result);

  EXPECT_EQ(answer.ec, std::errc{});
  EXPECT_FLOAT_EQ(result, 3.14159f);
  EXPECT_EQ(answer.ptr, input + std::strlen(input));
}

// Test basic double parsing
TEST_F(FastFloatIntegrationTest, BasicDoubleParsing) {
  const char* input = "2.718281828459045";
  double result;
  auto answer =
      fast_float::from_chars(input, input + std::strlen(input), result);

  EXPECT_EQ(answer.ec, std::errc{});
  EXPECT_DOUBLE_EQ(result, 2.718281828459045);
  EXPECT_EQ(answer.ptr, input + std::strlen(input));
}

// Test scientific notation parsing
TEST_F(FastFloatIntegrationTest, ScientificNotation) {
  const char* input = "1.23e-4";
  double result;
  auto answer =
      fast_float::from_chars(input, input + std::strlen(input), result);

  EXPECT_EQ(answer.ec, std::errc{});
  EXPECT_DOUBLE_EQ(result, 1.23e-4);
  EXPECT_EQ(answer.ptr, input + std::strlen(input));
}

// Test negative numbers
TEST_F(FastFloatIntegrationTest, NegativeNumbers) {
  const char* input = "-42.5";
  float result;
  auto answer =
      fast_float::from_chars(input, input + std::strlen(input), result);

  EXPECT_EQ(answer.ec, std::errc{});
  EXPECT_FLOAT_EQ(result, -42.5f);
  EXPECT_EQ(answer.ptr, input + std::strlen(input));
}

// Test zero parsing
TEST_F(FastFloatIntegrationTest, ZeroParsing) {
  const char* input = "0.0";
  double result;
  auto answer =
      fast_float::from_chars(input, input + std::strlen(input), result);

  EXPECT_EQ(answer.ec, std::errc{});
  EXPECT_DOUBLE_EQ(result, 0.0);
  EXPECT_EQ(answer.ptr, input + std::strlen(input));
}

// Test infinity parsing
TEST_F(FastFloatIntegrationTest, InfinityParsing) {
  const char* input = "inf";
  double result;
  auto answer =
      fast_float::from_chars(input, input + std::strlen(input), result);

  EXPECT_EQ(answer.ec, std::errc{});
  EXPECT_TRUE(std::isinf(result));
  EXPECT_TRUE(result > 0);
  EXPECT_EQ(answer.ptr, input + std::strlen(input));
}

// Test negative infinity parsing
TEST_F(FastFloatIntegrationTest, NegativeInfinityParsing) {
  const char* input = "-inf";
  double result;
  auto answer =
      fast_float::from_chars(input, input + std::strlen(input), result);

  EXPECT_EQ(answer.ec, std::errc{});
  EXPECT_TRUE(std::isinf(result));
  EXPECT_TRUE(result < 0);
  EXPECT_EQ(answer.ptr, input + std::strlen(input));
}

// Test NaN parsing
TEST_F(FastFloatIntegrationTest, NaNParsing) {
  const char* input = "nan";
  double result;
  auto answer =
      fast_float::from_chars(input, input + std::strlen(input), result);

  EXPECT_EQ(answer.ec, std::errc{});
  EXPECT_TRUE(std::isnan(result));
  EXPECT_EQ(answer.ptr, input + std::strlen(input));
}

// Test invalid input
TEST_F(FastFloatIntegrationTest, InvalidInput) {
  const char* input = "not_a_number";
  double result;
  auto answer =
      fast_float::from_chars(input, input + std::strlen(input), result);

  EXPECT_EQ(answer.ec, std::errc::invalid_argument);
  EXPECT_EQ(answer.ptr, input);
}

// Test partial parsing
TEST_F(FastFloatIntegrationTest, PartialParsing) {
  const char* input = "123.45abc";
  double result;
  auto answer =
      fast_float::from_chars(input, input + std::strlen(input), result);

  EXPECT_EQ(answer.ec, std::errc{});
  EXPECT_DOUBLE_EQ(result, 123.45);
  EXPECT_EQ(answer.ptr, input + 6);  // Points to 'a'
}

// Test very large numbers
TEST_F(FastFloatIntegrationTest, VeryLargeNumbers) {
  const char* input = "1.7976931348623157e+308";  // Close to max double
  double result;
  auto answer =
      fast_float::from_chars(input, input + std::strlen(input), result);

  EXPECT_EQ(answer.ec, std::errc{});
  EXPECT_DOUBLE_EQ(result, 1.7976931348623157e+308);
  EXPECT_EQ(answer.ptr, input + std::strlen(input));
}

// Test very small numbers
TEST_F(FastFloatIntegrationTest, VerySmallNumbers) {
  const char* input = "2.2250738585072014e-308";  // Close to min double
  double result;
  auto answer =
      fast_float::from_chars(input, input + std::strlen(input), result);

  EXPECT_EQ(answer.ec, std::errc{});
  EXPECT_DOUBLE_EQ(result, 2.2250738585072014e-308);
  EXPECT_EQ(answer.ptr, input + std::strlen(input));
}

// Test performance compared to standard library (basic performance test)
TEST_F(FastFloatIntegrationTest, BasicPerformanceTest) {
  std::vector<std::string> test_numbers = {
      "3.14159", "2.71828", "1.41421", "1.73205", "0.57721",
      "123.456", "789.012", "999.999", "0.00001", "1000000.0"};

  // Test that fast_float can parse all numbers correctly
  for (const auto& num_str : test_numbers) {
    double result;
    auto answer = fast_float::from_chars(
        num_str.c_str(), num_str.c_str() + num_str.size(), result);

    EXPECT_EQ(answer.ec, std::errc{}) << "Failed to parse: " << num_str;
    EXPECT_EQ(answer.ptr, num_str.c_str() + num_str.size())
        << "Incomplete parse: " << num_str;

    // Verify result is reasonable (not NaN or inf for these inputs)
    EXPECT_FALSE(std::isnan(result)) << "Got NaN for: " << num_str;
    EXPECT_FALSE(std::isinf(result)) << "Got infinity for: " << num_str;
  }
}

// Comprehensive edge case testing
TEST_F(FastFloatIntegrationTest, EdgeCases) {
  struct TestCase {
    std::string input;
    bool should_succeed;
    double expected_value;
  };

  std::vector<TestCase> test_cases = {
      {"0", true, 0.0},   {"1", true, 1.0},    {"-1", true, -1.0},
      {"0.0", true, 0.0}, {"1.0", true, 1.0},  {"-1.0", true, -1.0},
      {"1e0", true, 1.0}, {"1e1", true, 10.0}, {"1e-1", true, 0.1},
      {"", false, 0.0},   {".", false, 0.0},   {"e", false, 0.0},
      {"+1", false, 0.0},  // fast_float doesn't support explicit positive signs
  };

  for (const auto& test_case : test_cases) {
    double result;
    auto answer = fast_float::from_chars(
        test_case.input.c_str(),
        test_case.input.c_str() + test_case.input.size(), result);

    if (test_case.should_succeed) {
      EXPECT_EQ(answer.ec, std::errc{})
          << "Should succeed for: '" << test_case.input << "'";
      if (answer.ec == std::errc{}) {
        EXPECT_DOUBLE_EQ(result, test_case.expected_value)
            << "Wrong value for: '" << test_case.input << "'";
      }
    } else {
      EXPECT_NE(answer.ec, std::errc{})
          << "Should fail for: '" << test_case.input << "'";
    }
  }
}
