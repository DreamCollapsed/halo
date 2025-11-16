#include <folly/FBString.h>
#include <folly/hash/Hash.h>

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
  auto high_bits = static_cast<unsigned __int128>(0x0123456789abcdefULL) << 64;
  auto low_bits = static_cast<unsigned __int128>(0xfedcba9876543210ULL);
  unsigned __int128 u128 = high_bits | low_bits;

  // Folly hasher for unsigned __int128 should reduce to hash_128_to_64(hi, lo)
  folly::Hash hash_fn;
  size_t hash_value = hash_fn(u128);

  uint64_t expect = folly::hash::hash_128_to_64(
      static_cast<uint64_t>(u128 >> 64), static_cast<uint64_t>(u128));
  EXPECT_EQ(hash_value, static_cast<size_t>(expect));
}

TEST(FollyIntegration, Int128HasherSignedAndUnsigned) {
  auto unsigned_value = (static_cast<unsigned __int128>(0xABCD1234ULL) << 96) |
                        (static_cast<unsigned __int128>(0x5678ULL) << 64) |
                        (static_cast<unsigned __int128>(0x9ABCDEF0ULL) << 32) |
                        static_cast<unsigned __int128>(0x13579BDFULL);
  auto signed_value = static_cast<signed __int128>(unsigned_value);

  folly::Hash hash_fn;
  auto unsigned_hash = hash_fn(unsigned_value);
  auto signed_hash = hash_fn(signed_value);

  // When values compare equal as 128-bit integers, their hash should match
  EXPECT_EQ(unsigned_hash, signed_hash);
}

TEST(FollyIntegration, Int128InUnorderedMap) {
  std::unordered_map<unsigned __int128, int, folly::hasher<unsigned __int128>>
      value_map;

  auto make128 = [](uint64_t high_word,
                    uint64_t low_word) -> unsigned __int128 {
    return (static_cast<unsigned __int128>(high_word) << 64) | low_word;
  };

  auto key_one = make128(0, 1);
  auto key_two = make128(1, 0);
  auto key_three = make128(0xDEADBEEFDEADBEEFULL, 0xCAFEBABECAFEBABELL);

  value_map[key_one] = 10;
  value_map[key_two] = 20;
  value_map[key_three] = 30;

  EXPECT_EQ(value_map.at(key_one), 10);
  EXPECT_EQ(value_map.at(key_two), 20);
  EXPECT_EQ(value_map.at(key_three), 30);
}

TEST(FollyIntegration, Int128HasherFunctor) {
  // Directly use folly::hasher for 128-bit integers
  folly::hasher<signed __int128> signed_hasher;
  folly::hasher<unsigned __int128> unsigned_hasher;

  auto make128 = [](uint64_t high_word,
                    uint64_t low_word) -> unsigned __int128 {
    return (static_cast<unsigned __int128>(high_word) << 64) | low_word;
  };

  auto unsigned_value = make128(0x0123456789ABCDEFULL, 0x0FEDCBA987654321ULL);
  auto signed_value = static_cast<signed __int128>(unsigned_value);

  // hasher should reduce to hash_128_to_64 of hi/lo per folly implementation
  size_t hu_val = unsigned_hasher(unsigned_value);
  size_t hs_val = signed_hasher(signed_value);

  uint64_t expect =
      folly::hash::hash_128_to_64(static_cast<uint64_t>(unsigned_value >> 64),
                                  static_cast<uint64_t>(unsigned_value));

  EXPECT_EQ(hu_val, static_cast<size_t>(expect));
  EXPECT_EQ(hs_val, static_cast<size_t>(expect));

  // Basic sanity: changing a bit changes the hash
  auto toggled_value = unsigned_value ^ static_cast<unsigned __int128>(1);
  EXPECT_NE(unsigned_hasher(toggled_value), hu_val);
}
