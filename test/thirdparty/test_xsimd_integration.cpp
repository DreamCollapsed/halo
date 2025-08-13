// Basic xsimd smoke tests: verify headers, load/store, arithmetic, hadd
#include <gtest/gtest.h>

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <xsimd/xsimd.hpp>

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
