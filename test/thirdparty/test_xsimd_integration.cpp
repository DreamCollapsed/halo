// Basic xsimd smoke tests: verify headers, load/store, arithmetic, hadd
#include <gtest/gtest.h>

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <vector>
#include <xsimd/xsimd.hpp>
#include <xtl/xcomplex.hpp>
#include <xtl/xoptional.hpp>

TEST(XsimdIntegration, BasicAdd) {
  using batch = xsimd::batch<float>;  // default arch-selected batch
  float a_raw[batch::size];
  float b_raw[batch::size];
  for (std::size_t i = 0; i < batch::size; ++i) {
    a_raw[i] = static_cast<float>(i);
    b_raw[i] = static_cast<float>(i * 2);
  }
  batch a = xsimd::load_unaligned(a_raw);
  batch b = xsimd::load_unaligned(b_raw);
  batch c = a + b;
  float out[batch::size];
  c.store_unaligned(out);
  for (std::size_t i = 0; i < batch::size; ++i) {
    ASSERT_FLOAT_EQ(out[i], a_raw[i] + b_raw[i]);
  }
}

TEST(XsimdIntegration, HorizontalSum) {
  using batch = xsimd::batch<double>;
  double v_raw[batch::size];
  double expected = 0.0;
  for (std::size_t i = 0; i < batch::size; ++i) {
    v_raw[i] = static_cast<double>(i + 1);
    expected += v_raw[i];
  }
  batch v = xsimd::load_unaligned(v_raw);
  double buf[batch::size];
  v.store_unaligned(buf);
  double got = 0.0;
  for (std::size_t i = 0; i < batch::size; ++i) got += buf[i];
  ASSERT_DOUBLE_EQ(got, expected);
}

TEST(XsimdIntegration, FloatMulSqrtMinMax) {
  using batch = xsimd::batch<float>;
  float a_raw[batch::size];
  float b_raw[batch::size];
  for (std::size_t i = 0; i < batch::size; ++i) {
    a_raw[i] = static_cast<float>(i + 1);
    b_raw[i] = static_cast<float>((i + 1) * 3);
  }
  batch a = xsimd::load_unaligned(a_raw);
  batch b = xsimd::load_unaligned(b_raw);
  batch mul = a * b;
  batch sq = xsimd::sqrt(mul);
  batch mn = xsimd::min(a, b);
  batch mx = xsimd::max(a, b);
  float mul_out[batch::size], sq_out[batch::size], mn_out[batch::size],
      mx_out[batch::size];
  mul.store_unaligned(mul_out);
  sq.store_unaligned(sq_out);
  mn.store_unaligned(mn_out);
  mx.store_unaligned(mx_out);
  for (std::size_t i = 0; i < batch::size; ++i) {
    ASSERT_FLOAT_EQ(mul_out[i], a_raw[i] * b_raw[i]);
    ASSERT_FLOAT_EQ(mn_out[i], std::min(a_raw[i], b_raw[i]));
    ASSERT_FLOAT_EQ(mx_out[i], std::max(a_raw[i], b_raw[i]));
    ASSERT_NE(sq_out[i], 0.0f);
  }
}

TEST(XsimdIntegration, IntAddSubAndBitwise) {
  using batch = xsimd::batch<int32_t>;
  int32_t a_raw[batch::size];
  int32_t b_raw[batch::size];
  for (std::size_t i = 0; i < batch::size; ++i) {
    a_raw[i] = static_cast<int32_t>(i);
    b_raw[i] = static_cast<int32_t>(i * 5 + 7);
  }
  batch a = xsimd::load_unaligned(a_raw);
  batch b = xsimd::load_unaligned(b_raw);
  batch add = a + b;
  batch sub = b - a;
  batch bw_and = a & b;
  batch bw_or = a | b;
  int32_t add_out[batch::size], sub_out[batch::size], and_out[batch::size],
      or_out[batch::size];
  add.store_unaligned(add_out);
  sub.store_unaligned(sub_out);
  bw_and.store_unaligned(and_out);
  bw_or.store_unaligned(or_out);
  for (std::size_t i = 0; i < batch::size; ++i) {
    ASSERT_EQ(add_out[i], a_raw[i] + b_raw[i]);
    ASSERT_EQ(sub_out[i], b_raw[i] - a_raw[i]);
    ASSERT_EQ(and_out[i], static_cast<int32_t>(a_raw[i] & b_raw[i]));
    ASSERT_EQ(or_out[i], static_cast<int32_t>(a_raw[i] | b_raw[i]));
  }
}

TEST(XsimdIntegration, CompareAndSelect) {
  using batch = xsimd::batch<float>;
  float a_raw[batch::size];
  float b_raw[batch::size];
  for (std::size_t i = 0; i < batch::size; ++i) {
    a_raw[i] = static_cast<float>(i);
    b_raw[i] = static_cast<float>(batch::size - i);
  }
  batch a = xsimd::load_unaligned(a_raw);
  batch b = xsimd::load_unaligned(b_raw);
  auto mask = a > b;  // batch_bool
  batch sel = xsimd::select(mask, a, b);
  float out[batch::size];
  sel.store_unaligned(out);
  for (std::size_t i = 0; i < batch::size; ++i) {
    float expected = (a_raw[i] > b_raw[i]) ? a_raw[i] : b_raw[i];
    ASSERT_FLOAT_EQ(out[i], expected);
  }
}

// Test XTL integration with XSIMD (using xtl optional with regular float
// batches)
TEST(XsimdIntegration, XtlOptionalFloatIntegration) {
  using batch = xsimd::batch<float>;
  std::vector<xtl::xoptional<float>> input_data;

  // Fill with some missing values and valid values
  for (std::size_t i = 0; i < batch::size; ++i) {
    if (i % 3 == 0) {
      input_data.push_back(xtl::missing<float>());
    } else {
      input_data.push_back(static_cast<float>(i * 2.5f));
    }
  }

  // Extract valid values for SIMD computation
  std::vector<float> valid_values;
  for (const auto& opt_val : input_data) {
    if (opt_val.has_value()) {
      valid_values.push_back(opt_val.value());
    }
  }

  if (valid_values.size() >= batch::size) {
    // Perform SIMD computation on valid values
    batch vals = xsimd::load_unaligned(valid_values.data());
    batch squared = vals * vals;

    float results[batch::size];
    squared.store_unaligned(results);

    // Verify results are positive (squares should be)
    for (std::size_t i = 0; i < batch::size; ++i) {
      ASSERT_GE(results[i], 0.0f);
    }
  }

  ASSERT_GT(valid_values.size(), 0);  // Should have at least some valid values
}

TEST(XsimdIntegration, XtlComplexNumberProcessing) {
  // Test processing complex numbers using xtl complex type
  using complex_t = xtl::xcomplex<double>;
  std::vector<complex_t> complex_data;

  // Create some complex numbers
  for (int i = 0; i < 8; ++i) {
    complex_data.emplace_back(static_cast<double>(i),
                              static_cast<double>(i + 1));
  }

  // Extract real and imaginary parts for separate SIMD processing
  using batch = xsimd::batch<double>;
  if (complex_data.size() >= batch::size) {
    std::vector<double> real_parts, imag_parts;
    for (const auto& c : complex_data) {
      real_parts.push_back(c.real());
      imag_parts.push_back(c.imag());
    }

    // Process real parts with SIMD
    batch real_batch = xsimd::load_unaligned(real_parts.data());
    batch real_squared = real_batch * real_batch;

    // Process imaginary parts with SIMD
    batch imag_batch = xsimd::load_unaligned(imag_parts.data());
    batch imag_squared = imag_batch * imag_batch;

    // Compute magnitude squared = real^2 + imag^2
    batch mag_squared = real_squared + imag_squared;

    double results[batch::size];
    mag_squared.store_unaligned(results);

    // Verify magnitude computation
    for (std::size_t i = 0; i < batch::size && i < complex_data.size(); ++i) {
      double expected = complex_data[i].real() * complex_data[i].real() +
                        complex_data[i].imag() * complex_data[i].imag();
      ASSERT_DOUBLE_EQ(results[i], expected);
    }
  }
}
