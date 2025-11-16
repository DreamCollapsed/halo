#include <double-conversion/double-conversion.h>
#include <gtest/gtest.h>

#include <array>
#include <chrono>
#include <cstring>
#include <iostream>
#include <limits>
#include <memory>
#include <string>

// Test fixture for double-conversion integration tests
class DoubleConversionIntegrationTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // Set up conversion flags
    conversion_flags_ = double_conversion::DoubleToStringConverter::NO_FLAGS;

    // Create converter with default settings
    converter_ = std::make_unique<double_conversion::DoubleToStringConverter>(
        conversion_flags_, "Infinity", "NaN", 'e',
        -6,  // decimal_in_shortest_low
        21,  // decimal_in_shortest_high
        6,   // max_leading_padding_zeroes_in_precision_mode
        6    // max_trailing_padding_zeroes_in_precision_mode
    );
  }

  void TearDown() override { converter_.reset(); }

  double_conversion::DoubleToStringConverter* Converter() {
    return converter_.get();
  }

  [[nodiscard]] const double_conversion::DoubleToStringConverter* Converter()
      const {
    return converter_.get();
  }

 private:
  double_conversion::DoubleToStringConverter::Flags conversion_flags_ =
      double_conversion::DoubleToStringConverter::NO_FLAGS;
  std::unique_ptr<double_conversion::DoubleToStringConverter> converter_;
};

// Test basic double to string conversion
TEST_F(DoubleConversionIntegrationTest, BasicDoubleToString) {
  std::array<char, 128> buffer{};
  double_conversion::StringBuilder builder(buffer.data(),
                                           static_cast<int>(buffer.size()));

  // Test positive number
  double value = 123.456;
  EXPECT_TRUE(Converter()->ToShortest(value, &builder));
  std::string result(buffer.data(), static_cast<size_t>(builder.position()));
  EXPECT_EQ(result, "123.456");

  // Reset builder
  builder.Reset();

  // Test negative number
  value = -789.012;
  EXPECT_TRUE(Converter()->ToShortest(value, &builder));
  result = std::string(buffer.data(), static_cast<size_t>(builder.position()));
  EXPECT_EQ(result, "-789.012");
}

// Test integer conversion
TEST_F(DoubleConversionIntegrationTest, IntegerConversion) {
  std::array<char, 128> buffer{};
  double_conversion::StringBuilder builder(buffer.data(),
                                           static_cast<int>(buffer.size()));

  // Test positive integer
  double value = 42.0;
  EXPECT_TRUE(Converter()->ToShortest(value, &builder));
  std::string result(buffer.data(), static_cast<size_t>(builder.position()));
  EXPECT_EQ(result, "42");

  // Reset builder
  builder.Reset();

  // Test zero
  value = 0.0;
  EXPECT_TRUE(Converter()->ToShortest(value, &builder));
  result = std::string(buffer.data(), static_cast<size_t>(builder.position()));
  EXPECT_EQ(result, "0");
}

// Test special values
TEST_F(DoubleConversionIntegrationTest, SpecialValues) {
  std::array<char, 128> buffer{};
  double_conversion::StringBuilder builder(buffer.data(),
                                           static_cast<int>(buffer.size()));

  // Test infinity
  double value = std::numeric_limits<double>::infinity();
  EXPECT_TRUE(Converter()->ToShortest(value, &builder));
  std::string result(buffer.data(), static_cast<size_t>(builder.position()));
  EXPECT_EQ(result, "Infinity");

  // Reset builder
  builder.Reset();

  // Test negative infinity
  value = -std::numeric_limits<double>::infinity();
  EXPECT_TRUE(Converter()->ToShortest(value, &builder));
  result = std::string(buffer.data(), static_cast<size_t>(builder.position()));
  EXPECT_EQ(result, "-Infinity");

  // Reset builder
  builder.Reset();

  // Test NaN
  value = std::numeric_limits<double>::quiet_NaN();
  EXPECT_TRUE(Converter()->ToShortest(value, &builder));
  result = std::string(buffer.data(), static_cast<size_t>(builder.position()));
  EXPECT_EQ(result, "NaN");
}

// Test scientific notation
TEST_F(DoubleConversionIntegrationTest, ScientificNotation) {
  std::array<char, 128> buffer{};
  double_conversion::StringBuilder builder(buffer.data(),
                                           static_cast<int>(buffer.size()));

  // Test very large number - use a number that definitely requires scientific
  // notation
  double value = 1.23456789e25;  // Much larger number
  EXPECT_TRUE(Converter()->ToShortest(value, &builder));
  std::string result(buffer.data(), static_cast<size_t>(builder.position()));
  // For very large numbers, scientific notation should be used
  EXPECT_TRUE(result.find('e') != std::string::npos ||
              result.find('E') != std::string::npos);

  // Reset builder
  builder.Reset();

  // Test very small number - use a number that definitely requires scientific
  // notation
  value = 1.23456789e-25;  // Much smaller number
  EXPECT_TRUE(Converter()->ToShortest(value, &builder));
  result = std::string(buffer.data(), static_cast<size_t>(builder.position()));
  // For very small numbers, scientific notation should be used
  EXPECT_TRUE(result.find('e') != std::string::npos ||
              result.find('E') != std::string::npos);
}

// Test string to double conversion
TEST_F(DoubleConversionIntegrationTest, StringToDouble) {
  double_conversion::StringToDoubleConverter string_converter(
      double_conversion::StringToDoubleConverter::NO_FLAGS,
      0.0,                                       // empty_string_value
      std::numeric_limits<double>::quiet_NaN(),  // junk_string_value
      "Infinity", "NaN");

  // Test basic conversion
  const char* input = "123.456";
  int processed_chars = 0;
  double result = string_converter.StringToDouble(
      input, static_cast<int>(std::strlen(input)), &processed_chars);
  EXPECT_DOUBLE_EQ(result, 123.456);
  EXPECT_EQ(processed_chars, 7);

  // Test negative number
  input = "-789.012";
  result = string_converter.StringToDouble(
      input, static_cast<int>(std::strlen(input)), &processed_chars);
  EXPECT_DOUBLE_EQ(result, -789.012);
  EXPECT_EQ(processed_chars, 8);

  // Test scientific notation
  input = "1.23e10";
  result = string_converter.StringToDouble(
      input, static_cast<int>(std::strlen(input)), &processed_chars);
  EXPECT_DOUBLE_EQ(result, 1.23e10);
  EXPECT_EQ(processed_chars, 7);
}

// Test precision conversion
TEST_F(DoubleConversionIntegrationTest, PrecisionConversion) {
  std::array<char, 128> buffer{};
  double_conversion::StringBuilder builder(buffer.data(),
                                           static_cast<int>(buffer.size()));

  double value = 1.0 / 3.0;  // 0.33333...

  // Test with 3 digits precision
  EXPECT_TRUE(Converter()->ToPrecision(value, 3, &builder));
  std::string result(buffer.data(), static_cast<size_t>(builder.position()));
  EXPECT_EQ(result, "0.333");

  // Reset builder
  builder.Reset();

  // Test with 6 digits precision
  EXPECT_TRUE(Converter()->ToPrecision(value, 6, &builder));
  result = std::string(buffer.data(), static_cast<size_t>(builder.position()));
  EXPECT_EQ(result, "0.333333");
}

// Test fixed-point conversion
TEST_F(DoubleConversionIntegrationTest, FixedPointConversion) {
  std::array<char, 128> buffer{};
  double_conversion::StringBuilder builder(buffer.data(),
                                           static_cast<int>(buffer.size()));

  double value = 123.456789;

  // Test with 2 decimal places
  EXPECT_TRUE(Converter()->ToFixed(value, 2, &builder));
  std::string result(buffer.data(), static_cast<size_t>(builder.position()));
  EXPECT_EQ(result, "123.46");

  // Reset builder
  builder.Reset();

  // Test with 4 decimal places
  EXPECT_TRUE(Converter()->ToFixed(value, 4, &builder));
  result = std::string(buffer.data(), static_cast<size_t>(builder.position()));
  EXPECT_EQ(result, "123.4568");
}

// Test exponential conversion
TEST_F(DoubleConversionIntegrationTest, ExponentialConversion) {
  std::array<char, 128> buffer{};
  double_conversion::StringBuilder builder(buffer.data(),
                                           static_cast<int>(buffer.size()));

  double value = 1234.5678;

  // Test with 3 decimal places in exponential format
  EXPECT_TRUE(Converter()->ToExponential(value, 3, &builder));
  std::string result(buffer.data(), static_cast<size_t>(builder.position()));
  EXPECT_TRUE(result.find('e') != std::string::npos);
  EXPECT_TRUE(result.find("1.235e") != std::string::npos);
}

// Test StringBuilder functionality
TEST_F(DoubleConversionIntegrationTest, StringBuilderTest) {
  std::array<char, 128> buffer{};
  double_conversion::StringBuilder builder(buffer.data(),
                                           static_cast<int>(buffer.size()));

  // Test initial state
  EXPECT_EQ(builder.position(), 0);
  EXPECT_EQ(builder.size(), 128);

  // Test adding characters
  builder.AddCharacter('H');
  builder.AddCharacter('e');
  builder.AddCharacter('l');
  builder.AddCharacter('l');
  builder.AddCharacter('o');

  EXPECT_EQ(builder.position(), 5);
  std::string result(buffer.data(), static_cast<size_t>(builder.position()));
  EXPECT_EQ(result, "Hello");

  // Test reset
  builder.Reset();
  EXPECT_EQ(builder.position(), 0);
}

// Performance test for conversion operations
TEST_F(DoubleConversionIntegrationTest, PerformanceTest) {
  const int NUM_CONVERSIONS = 10000;
  std::array<char, 128> buffer{};

  auto start = std::chrono::high_resolution_clock::now();

  for (int i = 0; i < NUM_CONVERSIONS; ++i) {
    double_conversion::StringBuilder builder(buffer.data(),
                                             static_cast<int>(buffer.size()));
    double value = static_cast<double>(i) + 0.123456789;
    Converter()->ToShortest(value, &builder);
  }

  auto end = std::chrono::high_resolution_clock::now();
  auto duration =
      std::chrono::duration_cast<std::chrono::microseconds>(end - start);

  // This should complete in reasonable time (less than 1 second)
  EXPECT_LT(duration.count(), 1000000);  // 1 second in microseconds
  std::cout << "Converted " << NUM_CONVERSIONS << " doubles in "
            << duration.count() << " microseconds\n";
}

// Test edge cases
TEST_F(DoubleConversionIntegrationTest, EdgeCases) {
  std::array<char, 128> buffer{};
  double_conversion::StringBuilder builder(buffer.data(),
                                           static_cast<int>(buffer.size()));

  // Test very small positive number
  double value = std::numeric_limits<double>::min();
  EXPECT_TRUE(Converter()->ToShortest(value, &builder));
  std::string result(buffer.data(), static_cast<size_t>(builder.position()));
  EXPECT_FALSE(result.empty());

  // Reset builder
  builder.Reset();

  // Test maximum finite value
  value = std::numeric_limits<double>::max();
  EXPECT_TRUE(Converter()->ToShortest(value, &builder));
  result = std::string(buffer.data(), static_cast<size_t>(builder.position()));
  EXPECT_FALSE(result.empty());
}

// Test round-trip conversion (double -> string -> double)
TEST_F(DoubleConversionIntegrationTest, RoundTripConversion) {
  double_conversion::StringToDoubleConverter string_converter(
      double_conversion::StringToDoubleConverter::NO_FLAGS, 0.0,
      std::numeric_limits<double>::quiet_NaN(), "Infinity", "NaN");

  double original_value = 123.456789012345;

  // Convert to string
  std::array<char, 128> buffer{};
  double_conversion::StringBuilder builder(buffer.data(),
                                           static_cast<int>(buffer.size()));
  EXPECT_TRUE(Converter()->ToShortest(original_value, &builder));
  std::string str_value(buffer.data(), static_cast<size_t>(builder.position()));

  // Convert back to double
  int processed_chars = 0;
  double converted_value = string_converter.StringToDouble(
      str_value.c_str(), static_cast<int>(str_value.length()),
      &processed_chars);

  // Should be very close to original (within floating point precision)
  EXPECT_DOUBLE_EQ(original_value, converted_value);
  EXPECT_EQ(processed_chars, static_cast<int>(str_value.length()));
}
