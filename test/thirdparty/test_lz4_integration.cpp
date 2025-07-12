#include <gtest/gtest.h>
#include <lz4.h>
#include <lz4hc.h>

#include <string>
#include <vector>

class Lz4IntegrationTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // Set up test data
    original_data =
        "This is a test string for lz4 compression and decompression. "
        "It should be long enough to demonstrate the compression capabilities. "
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. "
        "Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. "
        "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris. "
        "Nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in "
        "reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla "
        "pariatur.";
  }

  void TearDown() override {
    // Clean up if needed
  }

  std::string original_data;
};

// Test lz4 version and basic functionality
TEST_F(Lz4IntegrationTest, Lz4VersionTest) {
  // Test that we can get the lz4 version
  int version = LZ4_versionNumber();
  EXPECT_GT(version, 0);

  // Test that we have the expected version (1.10.0 as specified in
  // ComponentsInfo.cmake)
  int expected_version = 11000;  // 1.10.0 encoded as integer
  EXPECT_EQ(version, expected_version);

  // Test version string
  const char* version_string = LZ4_versionString();
  EXPECT_STREQ(version_string, "1.10.0");
}

// Test basic compression functionality
TEST_F(Lz4IntegrationTest, BasicCompressionTest) {
  // Get bounds for compression
  int max_compressed_size = LZ4_compressBound(original_data.size());
  EXPECT_GT(max_compressed_size, 0);

  // Allocate buffer for compressed data
  std::vector<char> compressed_data(max_compressed_size);

  // Compress the data
  int compressed_size =
      LZ4_compress_default(original_data.data(), compressed_data.data(),
                           original_data.size(), max_compressed_size);

  // Check that compression was successful
  EXPECT_GT(compressed_size, 0);
  EXPECT_LT(compressed_size,
            static_cast<int>(original_data.size()));  // Should be compressed

  // Resize the vector to actual compressed size
  compressed_data.resize(compressed_size);

  // Decompress the data
  std::vector<char> decompressed_data(original_data.size());
  int decompressed_size =
      LZ4_decompress_safe(compressed_data.data(), decompressed_data.data(),
                          compressed_size, original_data.size());

  // Check that decompression was successful
  EXPECT_GT(decompressed_size, 0);
  EXPECT_EQ(decompressed_size, static_cast<int>(original_data.size()));

  // Check that decompressed data matches original
  std::string decompressed_string(decompressed_data.data(), decompressed_size);
  EXPECT_EQ(decompressed_string, original_data);
}

// Test fast compression
TEST_F(Lz4IntegrationTest, FastCompressionTest) {
  // Get bounds for compression
  int max_compressed_size = LZ4_compressBound(original_data.size());
  EXPECT_GT(max_compressed_size, 0);

  // Allocate buffer for compressed data
  std::vector<char> compressed_data(max_compressed_size);

  // Compress the data using fast compression
  int compressed_size =
      LZ4_compress_fast(original_data.data(), compressed_data.data(),
                        original_data.size(), max_compressed_size,
                        1  // acceleration parameter (1 = default)
      );

  // Check that compression was successful
  EXPECT_GT(compressed_size, 0);

  // Decompress the data
  std::vector<char> decompressed_data(original_data.size());
  int decompressed_size =
      LZ4_decompress_safe(compressed_data.data(), decompressed_data.data(),
                          compressed_size, original_data.size());

  // Check that decompression was successful
  EXPECT_GT(decompressed_size, 0);
  EXPECT_EQ(decompressed_size, static_cast<int>(original_data.size()));

  // Check that decompressed data matches original
  std::string decompressed_string(decompressed_data.data(), decompressed_size);
  EXPECT_EQ(decompressed_string, original_data);
}

// Test high compression
TEST_F(Lz4IntegrationTest, HighCompressionTest) {
  // Get bounds for compression
  int max_compressed_size = LZ4_compressBound(original_data.size());
  EXPECT_GT(max_compressed_size, 0);

  // Allocate buffer for compressed data
  std::vector<char> compressed_data(max_compressed_size);

  // Compress the data using high compression
  int compressed_size = LZ4_compress_HC(
      original_data.data(), compressed_data.data(), original_data.size(),
      max_compressed_size, LZ4HC_CLEVEL_DEFAULT);

  // Check that compression was successful
  EXPECT_GT(compressed_size, 0);

  // Decompress the data
  std::vector<char> decompressed_data(original_data.size());
  int decompressed_size =
      LZ4_decompress_safe(compressed_data.data(), decompressed_data.data(),
                          compressed_size, original_data.size());

  // Check that decompression was successful
  EXPECT_GT(decompressed_size, 0);
  EXPECT_EQ(decompressed_size, static_cast<int>(original_data.size()));

  // Check that decompressed data matches original
  std::string decompressed_string(decompressed_data.data(), decompressed_size);
  EXPECT_EQ(decompressed_string, original_data);
}

// Test error handling
TEST_F(Lz4IntegrationTest, ErrorHandlingTest) {
  // Test compression with invalid parameters
  std::vector<char> small_buffer(1);  // Too small buffer

  int result = LZ4_compress_default(original_data.data(), small_buffer.data(),
                                    original_data.size(), small_buffer.size());

  // Should return 0 (failure)
  EXPECT_EQ(result, 0);

  // Test decompression with invalid data
  std::vector<char> invalid_compressed_data(10,
                                            'x');  // Invalid compressed data
  std::vector<char> decompressed_data(original_data.size());

  int decompress_result = LZ4_decompress_safe(
      invalid_compressed_data.data(), decompressed_data.data(),
      invalid_compressed_data.size(), decompressed_data.size());

  // Should return negative value (failure)
  EXPECT_LT(decompress_result, 0);
}

// Test streaming compression (if lz4 has streaming support)
TEST_F(Lz4IntegrationTest, StreamingTest) {
  // Test streaming compression and decompression
  // This is a basic test to ensure streaming APIs are available

  // Allocate stream state
  LZ4_stream_t* stream_state = LZ4_createStream();
  EXPECT_NE(stream_state, nullptr);

  // Get bounds for compression
  int max_compressed_size = LZ4_compressBound(original_data.size());
  std::vector<char> compressed_data(max_compressed_size);

  // Compress using streaming API
  int compressed_size = LZ4_compress_fast_continue(
      stream_state, original_data.data(), compressed_data.data(),
      original_data.size(), max_compressed_size, 1);

  EXPECT_GT(compressed_size, 0);

  // Clean up stream
  LZ4_freeStream(stream_state);

  // Test decompression
  std::vector<char> decompressed_data(original_data.size());
  int decompressed_size =
      LZ4_decompress_safe(compressed_data.data(), decompressed_data.data(),
                          compressed_size, original_data.size());

  EXPECT_GT(decompressed_size, 0);
  EXPECT_EQ(decompressed_size, static_cast<int>(original_data.size()));

  // Check that decompressed data matches original
  std::string decompressed_string(decompressed_data.data(), decompressed_size);
  EXPECT_EQ(decompressed_string, original_data);
}
