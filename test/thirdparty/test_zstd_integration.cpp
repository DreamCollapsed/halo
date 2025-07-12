#include <gtest/gtest.h>
#include <zstd.h>

#include <string>
#include <vector>

class ZstdIntegrationTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // Set up test data
    original_data =
        "This is a test string for zstd compression and decompression. "
        "It should be long enough to demonstrate the compression capabilities. "
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. "
        "Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. "
        "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.";
  }

  void TearDown() override {
    // Clean up if needed
  }

  std::string original_data;
};

// Test zstd version and basic functionality
TEST_F(ZstdIntegrationTest, ZstdVersionTest) {
  // Test that we can get the zstd version
  unsigned version = ZSTD_versionNumber();
  EXPECT_GT(version, 0);

  // Test that we have the expected version (1.5.7 as specified in
  // ComponentsInfo.cmake)
  unsigned expected_version = 10507;  // 1.5.7 encoded as integer
  EXPECT_EQ(version, expected_version);

  // Test version string
  const char* version_string = ZSTD_versionString();
  EXPECT_STREQ(version_string, "1.5.7");
}

// Test basic compression functionality
TEST_F(ZstdIntegrationTest, BasicCompressionTest) {
  // Get bounds for compression
  size_t compress_bound = ZSTD_compressBound(original_data.size());
  EXPECT_GT(compress_bound, 0);

  // Allocate buffer for compressed data
  std::vector<char> compressed_data(compress_bound);

  // Compress the data
  size_t compressed_size = ZSTD_compress(
      compressed_data.data(), compressed_data.size(), original_data.data(),
      original_data.size(), ZSTD_CLEVEL_DEFAULT);

  // Check that compression was successful
  EXPECT_FALSE(ZSTD_isError(compressed_size));
  EXPECT_GT(compressed_size, 0);
  EXPECT_LT(compressed_size, original_data.size());  // Should be compressed

  // Resize the vector to actual compressed size
  compressed_data.resize(compressed_size);

  // Get the original size from compressed data
  unsigned long long decompressed_size =
      ZSTD_getFrameContentSize(compressed_data.data(), compressed_data.size());
  EXPECT_EQ(decompressed_size, original_data.size());

  // Decompress the data
  std::vector<char> decompressed_data(decompressed_size);
  size_t actual_decompressed_size =
      ZSTD_decompress(decompressed_data.data(), decompressed_data.size(),
                      compressed_data.data(), compressed_data.size());

  // Check that decompression was successful
  EXPECT_FALSE(ZSTD_isError(actual_decompressed_size));
  EXPECT_EQ(actual_decompressed_size, original_data.size());

  // Check that decompressed data matches original
  std::string decompressed_string(decompressed_data.data(),
                                  actual_decompressed_size);
  EXPECT_EQ(decompressed_string, original_data);
}

// Test different compression levels
TEST_F(ZstdIntegrationTest, CompressionLevelsTest) {
  // Test minimum compression level
  int min_level = ZSTD_minCLevel();
  EXPECT_LE(min_level, 0);

  // Test maximum compression level
  int max_level = ZSTD_maxCLevel();
  EXPECT_GE(max_level, 1);

  // Test compression with different levels
  std::vector<int> levels = {1, 3, 6, 9, 12};

  for (int level : levels) {
    if (level <= max_level) {
      size_t compress_bound = ZSTD_compressBound(original_data.size());
      std::vector<char> compressed_data(compress_bound);

      size_t compressed_size =
          ZSTD_compress(compressed_data.data(), compressed_data.size(),
                        original_data.data(), original_data.size(), level);

      EXPECT_FALSE(ZSTD_isError(compressed_size));
      EXPECT_GT(compressed_size, 0);
    }
  }
}

// Test streaming compression (advanced feature)
TEST_F(ZstdIntegrationTest, StreamingCompressionTest) {
  // Create compression context
  ZSTD_CCtx* cctx = ZSTD_createCCtx();
  EXPECT_NE(cctx, nullptr);

  // Create decompression context
  ZSTD_DCtx* dctx = ZSTD_createDCtx();
  EXPECT_NE(dctx, nullptr);

  // Compress using streaming API
  size_t compress_bound = ZSTD_compressBound(original_data.size());
  std::vector<char> compressed_data(compress_bound);

  size_t compressed_size = ZSTD_compressCCtx(
      cctx, compressed_data.data(), compressed_data.size(),
      original_data.data(), original_data.size(), ZSTD_CLEVEL_DEFAULT);

  EXPECT_FALSE(ZSTD_isError(compressed_size));
  EXPECT_GT(compressed_size, 0);

  // Decompress using streaming API
  std::vector<char> decompressed_data(original_data.size());
  size_t decompressed_size = ZSTD_decompressDCtx(
      dctx, decompressed_data.data(), decompressed_data.size(),
      compressed_data.data(), compressed_size);

  EXPECT_FALSE(ZSTD_isError(decompressed_size));
  EXPECT_EQ(decompressed_size, original_data.size());

  // Verify data integrity
  std::string decompressed_string(decompressed_data.data(), decompressed_size);
  EXPECT_EQ(decompressed_string, original_data);

  // Clean up contexts
  ZSTD_freeCCtx(cctx);
  ZSTD_freeDCtx(dctx);
}

// Test error handling
TEST_F(ZstdIntegrationTest, ErrorHandlingTest) {
  // Test compression with invalid parameters
  std::vector<char> small_buffer(1);  // Too small buffer

  size_t result = ZSTD_compress(small_buffer.data(), small_buffer.size(),
                                original_data.data(), original_data.size(),
                                ZSTD_CLEVEL_DEFAULT);

  // Should return an error
  EXPECT_TRUE(ZSTD_isError(result));

  // Test getting error name
  const char* error_name = ZSTD_getErrorName(result);
  EXPECT_NE(error_name, nullptr);
  EXPECT_NE(strlen(error_name), 0);
}
