#include <gtest/gtest.h>
#include <xxhash.h>

#include <cstring>

// Integration tests for xxHash library

TEST(XXHashIntegrationTest, ConsistentHash32) {
  const char* data = "The quick brown fox jumps over the lazy dog";
  size_t len = std::strlen(data);
  unsigned int seed = 0;
  unsigned int h1 = XXH32(data, len, seed);
  unsigned int h2 = XXH32(data, len, seed);
  EXPECT_EQ(h1, h2) << "XXH32 should produce consistent results";
  EXPECT_NE(h1, 0u) << "Hash of non-empty data should not be zero";
}

TEST(XXHashIntegrationTest, Hash32EmptyData) {
  const char* data = "";
  unsigned int seed = 0;
  unsigned int h = XXH32(data, 0, seed);
  // XXH32 has a specific hash value for empty input, not zero
  EXPECT_EQ(h, 46947589u)
      << "XXH32 of empty data with seed 0 should have expected value";
}

TEST(XXHashIntegrationTest, ConsistentHash64) {
  const char* data = "Hello, xxHash!";
  size_t len = std::strlen(data);
  unsigned long long seed = 12345ULL;
  unsigned long long h1 = XXH64(data, len, seed);
  unsigned long long h2 = XXH64(data, len, seed);
  EXPECT_EQ(h1, h2) << "XXH64 should produce consistent results";
  EXPECT_NE(h1, 0ULL) << "Hash of non-empty data should not be zero";
}

TEST(XXHashIntegrationTest, Hash64EmptyData) {
  const char* data = "";
  unsigned long long seed = 0ULL;
  unsigned long long h = XXH64(data, 0, seed);
  // XXH64 has a specific hash value for empty input, not zero
  EXPECT_EQ(h, 17241709254077376921ULL)
      << "XXH64 of empty data with seed 0 should have expected value";
}
