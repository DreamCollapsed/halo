#include <folly/FBString.h>

#include <type_traits>

// Provide missing std::make_unsigned specializations for __int128 when using
// libstdc++.
// __int128 is a compiler extension; libstdc++ omits make_unsigned for it.
// Adding these locally enables folly hashing tests without polluting other
// translation units.
#if defined(__GLIBCXX__) && defined(__SIZEOF_INT128__)
namespace std {
template <>
struct make_unsigned<__int128> {
  using type = unsigned __int128;
};
template <>
struct make_unsigned<unsigned __int128> {
  using type = unsigned __int128;
};
}  // namespace std
static_assert(std::is_same_v<typename std::make_unsigned<__int128>::type,
                             unsigned __int128>,
              "make_unsigned<__int128> should map to unsigned __int128");
static_assert(
    std::is_same_v<typename std::make_unsigned<unsigned __int128>::type,
                   unsigned __int128>,
    "make_unsigned<unsigned __int128> should map to unsigned __int128");
#endif
#include <folly/folly-config.h>
#include <folly/hash/Hash.h>
#include <gtest/gtest.h>

#include <unordered_map>

TEST(FollyIntegration, FBStringBasic) {
  folly::fbstring str = "Hello";
  str += " Folly!";
  EXPECT_EQ(str, "Hello Folly!");
}

TEST(FollyIntegration, FBStringReserve) {
  folly::fbstring str;
  str.reserve(100);
  EXPECT_GE(str.capacity(), 100);
}

int main(int argc, char** argv) {
  testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}

TEST(FollyIntegration, Int128HasherMatches128Reducer) {
  // Construct a 128-bit value with specific hi/lo parts
  unsigned __int128 hi = static_cast<unsigned __int128>(0x0123456789abcdefULL)
                         << 64;
  unsigned __int128 lo = static_cast<unsigned __int128>(0xfedcba9876543210ULL);
  unsigned __int128 u128 = hi | lo;

  // Folly hasher for unsigned __int128 should reduce to hash_128_to_64(hi, lo)
  folly::Hash h;
  size_t hv = h(u128);

  uint64_t expect = folly::hash::hash_128_to_64(
      static_cast<uint64_t>(u128 >> 64), static_cast<uint64_t>(u128));
  EXPECT_EQ(hv, static_cast<size_t>(expect));
}

TEST(FollyIntegration, Int128HasherSignedAndUnsigned) {
  unsigned __int128 u = (static_cast<unsigned __int128>(0xABCD1234ULL) << 96) |
                        (static_cast<unsigned __int128>(0x5678ULL) << 64) |
                        (static_cast<unsigned __int128>(0x9ABCDEF0ULL) << 32) |
                        static_cast<unsigned __int128>(0x13579BDFULL);
  signed __int128 s = static_cast<signed __int128>(u);

  folly::Hash h;
  auto hu = h(u);
  auto hs = h(s);

  // When values compare equal as 128-bit integers, their hash should match
  EXPECT_EQ(hu, hs);
}

TEST(FollyIntegration, Int128InUnorderedMap) {
  std::unordered_map<unsigned __int128, int, folly::hasher<unsigned __int128>>
      m;

  auto make128 = [](uint64_t hi, uint64_t lo) -> unsigned __int128 {
    return (static_cast<unsigned __int128>(hi) << 64) | lo;
  };

  auto k1 = make128(0, 1);
  auto k2 = make128(1, 0);
  auto k3 = make128(0xDEADBEEFDEADBEEFULL, 0xCAFEBABECAFEBABELL);

  m[k1] = 10;
  m[k2] = 20;
  m[k3] = 30;

  EXPECT_EQ(m.at(k1), 10);
  EXPECT_EQ(m.at(k2), 20);
  EXPECT_EQ(m.at(k3), 30);
}

TEST(FollyIntegration, Int128HasherFunctor) {
  // Directly use folly::hasher for 128-bit integers
  folly::hasher<signed __int128> hs;
  folly::hasher<unsigned __int128> hu;

  auto make128 = [](uint64_t hi, uint64_t lo) -> unsigned __int128 {
    return (static_cast<unsigned __int128>(hi) << 64) | lo;
  };

  auto u = make128(0x0123456789ABCDEFULL, 0x0FEDCBA987654321ULL);
  auto s = static_cast<signed __int128>(u);

  // hasher should reduce to hash_128_to_64 of hi/lo per folly implementation
  size_t hu_val = hu(u);
  size_t hs_val = hs(s);

  uint64_t expect = folly::hash::hash_128_to_64(static_cast<uint64_t>(u >> 64),
                                                static_cast<uint64_t>(u));

  EXPECT_EQ(hu_val, static_cast<size_t>(expect));
  EXPECT_EQ(hs_val, static_cast<size_t>(expect));

  // Basic sanity: changing a bit changes the hash
  auto u2 = u ^ static_cast<unsigned __int128>(1);
  EXPECT_NE(hu(u2), hu_val);
}