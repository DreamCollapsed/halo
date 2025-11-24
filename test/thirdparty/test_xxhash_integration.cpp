#include <gtest/gtest.h>
#include <xxhash.h>

#include <cstdint>
#include <cstring>

// Integration tests for xxHash library

TEST(XXHashIntegrationTest, ConsistentHash32) {
  const char* data = "The quick brown fox jumps over the lazy dog";
  size_t len = std::strlen(data);
  unsigned int seed = 0;
  unsigned int hash1 = XXH32(data, len, seed);
  unsigned int hash2 = XXH32(data, len, seed);
  EXPECT_EQ(hash1, hash2) << "XXH32 should produce consistent results";
  EXPECT_NE(hash1, 0U) << "Hash of non-empty data should not be zero";
}

TEST(XXHashIntegrationTest, Hash32EmptyData) {
  const char* data = "";
  unsigned int seed = 0;
  unsigned int hash_val = XXH32(data, 0, seed);
  // XXH32 has a specific hash value for empty input, not zero
  EXPECT_EQ(hash_val, 46947589U)
      << "XXH32 of empty data with seed 0 should have expected value";
}

TEST(XXHashIntegrationTest, ConsistentHash64) {
  const char* data = "Hello, xxHash!";
  size_t len = std::strlen(data);
  uint64_t seed = 12345ULL;
  uint64_t hash1 = XXH64(data, len, seed);
  uint64_t hash2 = XXH64(data, len, seed);
  EXPECT_EQ(hash1, hash2) << "XXH64 should produce consistent results";
  EXPECT_NE(hash1, 0ULL) << "Hash of non-empty data should not be zero";
}

TEST(XXHashIntegrationTest, Hash64EmptyData) {
  const char* data = "";
  uint64_t seed = 0ULL;
  uint64_t hash_val = XXH64(data, 0, seed);
  // XXH64 has a specific hash value for empty input, not zero
  EXPECT_EQ(hash_val, 17241709254077376921ULL)
      << "XXH64 of empty data with seed 0 should have expected value";
}
