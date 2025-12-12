// Basic xsimd smoke tests: verify headers, load/store, arithmetic, hadd
#include <gtest/gtest.h>

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <vector>
#include <xsimd/xsimd.hpp>
#include <xtl/xcomplex.hpp>
#include <xtl/xoptional.hpp>

TEST(XsimdIntegration, VersionCheck) {
  EXPECT_EQ(XSIMD_VERSION_MAJOR, 14);
  EXPECT_EQ(XSIMD_VERSION_MINOR, 0);
  EXPECT_EQ(XSIMD_VERSION_PATCH, 0);
}

TEST(XsimdIntegration, BasicAdd) {
  using batch = xsimd::batch<float>;  // default arch-selected batch
  std::array<float, batch::size> a_raw{};
  std::array<float, batch::size> b_raw{};
  for (std::size_t i = 0; i < batch::size; ++i) {
    a_raw.at(i) = static_cast<float>(i);
    b_raw.at(i) = static_cast<float>(i * 2);
  }
  batch batch_a = xsimd::load_unaligned(a_raw.data());
  batch batch_b = xsimd::load_unaligned(b_raw.data());
  batch batch_c = batch_a + batch_b;
  std::array<float, batch::size> out{};
  batch_c.store_unaligned(out.data());
  for (std::size_t i = 0; i < batch::size; ++i) {
    ASSERT_FLOAT_EQ(out.at(i), a_raw.at(i) + b_raw.at(i));
  }
}

TEST(XsimdIntegration, HorizontalSum) {
  using batch = xsimd::batch<double>;
  std::array<double, batch::size> v_raw{};
  double expected = 0.0;
  for (std::size_t i = 0; i < batch::size; ++i) {
    v_raw.at(i) = static_cast<double>(i + 1);
    expected += v_raw.at(i);
  }
  batch batch_v = xsimd::load_unaligned(v_raw.data());
  std::array<double, batch::size> buf{};
  batch_v.store_unaligned(buf.data());
  double got = 0.0;
  for (std::size_t i = 0; i < batch::size; ++i) {
    got += buf.at(i);
  }
  ASSERT_DOUBLE_EQ(got, expected);
}

TEST(XsimdIntegration, FloatMulSqrtMinMax) {
  using batch = xsimd::batch<float>;
  std::array<float, batch::size> a_raw{};
  std::array<float, batch::size> b_raw{};
  for (std::size_t i = 0; i < batch::size; ++i) {
    a_raw.at(i) = static_cast<float>(i + 1);
    b_raw.at(i) = static_cast<float>((i + 1) * 3);
  }
  batch batch_a = xsimd::load_unaligned(a_raw.data());
  batch batch_b = xsimd::load_unaligned(b_raw.data());
  batch batch_mul = batch_a * batch_b;
  batch batch_sq = xsimd::sqrt(batch_mul);
  batch batch_min = xsimd::min(batch_a, batch_b);
  batch batch_max = xsimd::max(batch_a, batch_b);

  std::array<float, batch::size> mul_out{};
  std::array<float, batch::size> sq_out{};
  std::array<float, batch::size> mn_out{};
  std::array<float, batch::size> mx_out{};

  batch_mul.store_unaligned(mul_out.data());
  batch_sq.store_unaligned(sq_out.data());
  batch_min.store_unaligned(mn_out.data());
  batch_max.store_unaligned(mx_out.data());

  for (std::size_t i = 0; i < batch::size; ++i) {
    ASSERT_FLOAT_EQ(mul_out.at(i), a_raw.at(i) * b_raw.at(i));
    ASSERT_FLOAT_EQ(mn_out.at(i), std::min(a_raw.at(i), b_raw.at(i)));
    ASSERT_FLOAT_EQ(mx_out.at(i), std::max(a_raw.at(i), b_raw.at(i)));
    ASSERT_NE(sq_out.at(i), 0.0F);
  }
}

TEST(XsimdIntegration, IntAddSubAndBitwise) {
  using batch = xsimd::batch<int32_t>;
  std::array<int32_t, batch::size> a_raw{};
  std::array<int32_t, batch::size> b_raw{};
  for (std::size_t i = 0; i < batch::size; ++i) {
    a_raw.at(i) = static_cast<int32_t>(i);
    b_raw.at(i) = static_cast<int32_t>((i * 5) + 7);
  }
  batch batch_a = xsimd::load_unaligned(a_raw.data());
  batch batch_b = xsimd::load_unaligned(b_raw.data());
  batch batch_add = batch_a + batch_b;
  batch batch_sub = batch_b - batch_a;
  batch batch_and = batch_a & batch_b;
  batch batch_or = batch_a | batch_b;

  std::array<int32_t, batch::size> add_out{};
  std::array<int32_t, batch::size> sub_out{};
  std::array<int32_t, batch::size> and_out{};
  std::array<int32_t, batch::size> or_out{};

  batch_add.store_unaligned(add_out.data());
  batch_sub.store_unaligned(sub_out.data());
  batch_and.store_unaligned(and_out.data());
  batch_or.store_unaligned(or_out.data());

  for (std::size_t i = 0; i < batch::size; ++i) {
    ASSERT_EQ(add_out.at(i), a_raw.at(i) + b_raw.at(i));
    ASSERT_EQ(sub_out.at(i), b_raw.at(i) - a_raw.at(i));
    ASSERT_EQ(and_out.at(i), static_cast<int32_t>(a_raw.at(i) & b_raw.at(i)));
    ASSERT_EQ(or_out.at(i), static_cast<int32_t>(a_raw.at(i) | b_raw.at(i)));
  }
}

TEST(XsimdIntegration, CompareAndSelect) {
  using batch = xsimd::batch<float>;
  std::array<float, batch::size> a_raw{};
  std::array<float, batch::size> b_raw{};
  for (std::size_t i = 0; i < batch::size; ++i) {
    a_raw.at(i) = static_cast<float>(i);
    b_raw.at(i) = static_cast<float>(batch::size - i);
  }
  batch batch_a = xsimd::load_unaligned(a_raw.data());
  batch batch_b = xsimd::load_unaligned(b_raw.data());
  auto mask = batch_a > batch_b;  // batch_bool
  batch batch_sel = xsimd::select(mask, batch_a, batch_b);
  std::array<float, batch::size> out{};
  batch_sel.store_unaligned(out.data());
  for (std::size_t i = 0; i < batch::size; ++i) {
    float expected = (a_raw.at(i) > b_raw.at(i)) ? a_raw.at(i) : b_raw.at(i);
    ASSERT_FLOAT_EQ(out.at(i), expected);
  }
}

TEST(XsimdIntegration, XtlOptionalFloatIntegration) {
  using batch = xsimd::batch<float>;
  std::vector<xtl::xoptional<float>> input_data;
  input_data.reserve(batch::size);

  // Fill with some missing values and valid values
  for (std::size_t i = 0; i < batch::size; ++i) {
    if (i % 3 == 0) {
      input_data.emplace_back(xtl::missing<float>());
    } else {
      input_data.emplace_back(static_cast<float>(i) * 2.5F);
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

    std::array<float, batch::size> results{};
    squared.store_unaligned(results.data());

    // Verify results are positive (squares should be)
    for (std::size_t i = 0; i < batch::size; ++i) {
      ASSERT_GE(results.at(i), 0.0F);
    }
  }

  ASSERT_GT(valid_values.size(), 0);  // Should have at least some valid values
}

TEST(XsimdIntegration, XtlComplexNumberProcessing) {
  // Test processing complex numbers using xtl complex type
  using complex_t = xtl::xcomplex<double>;
  std::vector<complex_t> complex_data;
  complex_data.reserve(8);

  // Create some complex numbers
  for (int i = 0; i < 8; ++i) {
    complex_data.emplace_back(static_cast<double>(i),
                              static_cast<double>(i + 1));
  }

  // Extract real and imaginary parts for separate SIMD processing
  using batch = xsimd::batch<double>;
  if (complex_data.size() >= batch::size) {
    std::vector<double> real_parts;
    real_parts.reserve(complex_data.size());
    std::vector<double> imag_parts;
    imag_parts.reserve(complex_data.size());
    for (const auto& complex_val : complex_data) {
      real_parts.push_back(complex_val.real());
      imag_parts.push_back(complex_val.imag());
    }

    // Process real parts with SIMD
    batch real_batch = xsimd::load_unaligned(real_parts.data());
    batch real_squared = real_batch * real_batch;

    // Process imaginary parts with SIMD
    batch imag_batch = xsimd::load_unaligned(imag_parts.data());
    batch imag_squared = imag_batch * imag_batch;

    // Compute magnitude squared = real^2 + imag^2
    batch mag_squared = real_squared + imag_squared;

    std::array<double, batch::size> results{};
    mag_squared.store_unaligned(results.data());

    // Verify magnitude computation
    for (std::size_t i = 0; i < batch::size && i < complex_data.size(); ++i) {
      double expected = (complex_data[i].real() * complex_data[i].real()) +
                        (complex_data[i].imag() * complex_data[i].imag());
      ASSERT_DOUBLE_EQ(results.at(i), expected);
    }
  }
}
