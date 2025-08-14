#include <gtest/gtest.h>

#include <algorithm>
#include <array>
#include <complex>
#include <numeric>
#include <string>
#include <vector>
#include <xtl/xcomplex.hpp>
#include <xtl/xdynamic_bitset.hpp>
#include <xtl/xoptional.hpp>
#include <xtl/xspan.hpp>

TEST(XtlIntegration, OptionalBasic) {
  xtl::xoptional<int> oi = 42;
  ASSERT_TRUE(oi.has_value());
  EXPECT_EQ(oi.value(), 42);

  oi = xtl::missing<int>();
  EXPECT_FALSE(oi.has_value());
}

TEST(XtlIntegration, SpanView) {
  std::vector<int> v{1, 2, 3, 4, 5};
  xtl::span<int> s{v};
  ASSERT_EQ(s.size(), 5);
  s[0] = 10;
  EXPECT_EQ(v[0], 10);
}

TEST(XtlIntegration, OptionalChaining) {
  xtl::xoptional<int> a = 5;
  xtl::xoptional<int> b = 10;
  xtl::xoptional<int> c = xtl::missing<int>();

  // Test arithmetic with optional values
  auto sum_ab = a.has_value() && b.has_value()
                    ? xtl::xoptional<int>(a.value() + b.value())
                    : xtl::missing<int>();
  ASSERT_TRUE(sum_ab.has_value());
  EXPECT_EQ(sum_ab.value(), 15);

  // Test with missing value
  auto sum_ac = a.has_value() && c.has_value()
                    ? xtl::xoptional<int>(a.value() + c.value())
                    : xtl::missing<int>();
  EXPECT_FALSE(sum_ac.has_value());
}

TEST(XtlIntegration, OptionalCollections) {
  std::vector<xtl::xoptional<double>> data;
  data.push_back(1.5);
  data.push_back(xtl::missing<double>());
  data.push_back(3.7);
  data.push_back(2.1);
  data.push_back(xtl::missing<double>());

  // Count valid values
  std::size_t valid_count = 0;
  double sum = 0.0;
  for (const auto& opt : data) {
    if (opt.has_value()) {
      valid_count++;
      sum += opt.value();
    }
  }

  EXPECT_EQ(valid_count, 3);
  EXPECT_DOUBLE_EQ(sum, 7.3);

  // Calculate average of valid values
  double average = valid_count > 0 ? sum / valid_count : 0.0;
  EXPECT_DOUBLE_EQ(average, 7.3 / 3.0);
}

TEST(XtlIntegration, ComplexNumbers) {
  xtl::xcomplex<float> c1(3.0f, 4.0f);
  xtl::xcomplex<float> c2(1.0f, 2.0f);

  // Test basic operations
  auto sum = c1 + c2;
  EXPECT_FLOAT_EQ(sum.real(), 4.0f);
  EXPECT_FLOAT_EQ(sum.imag(), 6.0f);

  auto product = c1 * c2;
  // (3+4i) * (1+2i) = 3 + 6i + 4i + 8i^2 = 3 + 10i - 8 = -5 + 10i
  EXPECT_FLOAT_EQ(product.real(), -5.0f);
  EXPECT_FLOAT_EQ(product.imag(), 10.0f);

  // Test magnitude
  auto magnitude_sq = c1.real() * c1.real() + c1.imag() * c1.imag();
  EXPECT_FLOAT_EQ(magnitude_sq, 25.0f);  // 3^2 + 4^2 = 9 + 16 = 25
}

TEST(XtlIntegration, ComplexOptionalCombination) {
  std::vector<xtl::xoptional<xtl::xcomplex<double>>> complex_data;

  complex_data.push_back(xtl::xcomplex<double>(1.0, 1.0));
  complex_data.push_back(xtl::missing<xtl::xcomplex<double>>());
  complex_data.push_back(xtl::xcomplex<double>(2.0, -1.0));
  complex_data.push_back(xtl::xcomplex<double>(-1.0, 2.0));

  // Process only valid complex numbers
  std::vector<xtl::xcomplex<double>> valid_numbers;
  for (const auto& opt_complex : complex_data) {
    if (opt_complex.has_value()) {
      valid_numbers.push_back(opt_complex.value());
    }
  }

  EXPECT_EQ(valid_numbers.size(), 3);

  // Calculate sum of valid complex numbers
  xtl::xcomplex<double> total(0.0, 0.0);
  for (const auto& c : valid_numbers) {
    total =
        xtl::xcomplex<double>(total.real() + c.real(), total.imag() + c.imag());
  }

  EXPECT_DOUBLE_EQ(total.real(), 2.0);  // 1 + 2 + (-1) = 2
  EXPECT_DOUBLE_EQ(total.imag(), 2.0);  // 1 + (-1) + 2 = 2
}

TEST(XtlIntegration, SpanSubviews) {
  std::array<int, 10> data = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
  xtl::span<int> full_span(data);

  // Test subspan
  auto sub_span = full_span.subspan(2, 5);  // elements 2, 3, 4, 5, 6
  ASSERT_EQ(sub_span.size(), 5);
  EXPECT_EQ(sub_span[0], 2);
  EXPECT_EQ(sub_span[4], 6);

  // Modify through subspan
  sub_span[2] = 99;  // should modify data[4]
  EXPECT_EQ(data[4], 99);

  // Test first/last operations
  auto first_three = full_span.first(3);
  auto last_three = full_span.last(3);

  ASSERT_EQ(first_three.size(), 3);
  ASSERT_EQ(last_three.size(), 3);
  EXPECT_EQ(first_three[0], 0);
  EXPECT_EQ(last_three[0], 7);
}

TEST(XtlIntegration, DynamicBitset) {
  xtl::xdynamic_bitset<std::size_t> bits(16);

  // Set some bits
  bits.set(0);
  bits.set(3);
  bits.set(7);
  bits.set(15);

  EXPECT_TRUE(bits[0]);
  EXPECT_FALSE(bits[1]);
  EXPECT_TRUE(bits[3]);
  EXPECT_TRUE(bits[7]);
  EXPECT_TRUE(bits[15]);

  // Count set bits
  EXPECT_EQ(bits.count(), 4);

  // Test flip
  bits.flip(1);
  EXPECT_TRUE(bits[1]);
  EXPECT_EQ(bits.count(), 5);

  // Test reset
  bits.reset(3);
  EXPECT_FALSE(bits[3]);
  EXPECT_EQ(bits.count(), 4);
}
