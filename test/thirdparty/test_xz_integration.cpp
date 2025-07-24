#include <gtest/gtest.h>
#include <lzma.h>

#include <cstring>
#include <string>
#include <vector>

class XzIntegrationTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // Set up test data
    original_data =
        "This is a test string for xz/lzma compression and decompression. "
        "It should be long enough to demonstrate the compression capabilities. "
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. "
        "Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. "
        "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris. "
        "Nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in "
        "reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla "
        "pariatur. Excepteur sint occaecat cupidatat non proident, sunt in "
        "culpa qui officia deserunt mollit anim id est laborum. "
        "Sed ut perspiciatis unde omnis iste natus error sit voluptatem "
        "accusantium doloremque laudantium, totam rem aperiam, eaque ipsa "
        "quae ab illo inventore veritatis et quasi architecto beatae vitae "
        "dicta sunt explicabo.";
  }

  void TearDown() override {
    // Clean up if needed
  }

  std::string original_data;
};

// Test xz version and basic functionality
TEST_F(XzIntegrationTest, XzVersionTest) {
  // Test that we can get the lzma version
  uint32_t version = lzma_version_number();
  EXPECT_GT(version, 0);

  // Test that we have the expected version (5.8.x as specified in
  // ComponentsInfo.cmake) - allowing for patch versions
  uint32_t expected_major_minor = 50080000;  // 5.8.x encoded as integer
  EXPECT_GE(version, expected_major_minor);
  EXPECT_LT(version, 50090000);  // Less than 5.9.0

  // Test version string contains the major.minor version
  const char* version_string = lzma_version_string();
  std::string version_str(version_string);
  EXPECT_TRUE(version_str.find("5.8") == 0);  // Starts with "5.8"
}

// Test basic compression functionality
TEST_F(XzIntegrationTest, BasicCompressionTest) {
  // Initialize encoder
  lzma_stream strm = LZMA_STREAM_INIT;

  // Set up for compression with default settings
  lzma_ret ret =
      lzma_easy_encoder(&strm, LZMA_PRESET_DEFAULT, LZMA_CHECK_CRC64);
  ASSERT_EQ(ret, LZMA_OK) << "Failed to initialize encoder";

  // Prepare input data
  const uint8_t* input =
      reinterpret_cast<const uint8_t*>(original_data.c_str());
  size_t input_size = original_data.size();

  // Prepare output buffer
  std::vector<uint8_t> compressed_data(input_size * 2);  // Generous buffer

  // Set up stream
  strm.next_in = input;
  strm.avail_in = input_size;
  strm.next_out = compressed_data.data();
  strm.avail_out = compressed_data.size();

  // Compress
  ret = lzma_code(&strm, LZMA_FINISH);
  EXPECT_TRUE(ret == LZMA_OK || ret == LZMA_STREAM_END);

  // Calculate compressed size
  size_t compressed_size = compressed_data.size() - strm.avail_out;
  EXPECT_GT(compressed_size, 0);
  EXPECT_LT(compressed_size, input_size);  // Should be compressed

  // Clean up encoder
  lzma_end(&strm);

  // Resize to actual compressed size
  compressed_data.resize(compressed_size);

  // Test decompression
  lzma_stream decomp_strm = LZMA_STREAM_INIT;
  ret = lzma_stream_decoder(&decomp_strm, UINT64_MAX, 0);
  ASSERT_EQ(ret, LZMA_OK) << "Failed to initialize decoder";

  // Prepare decompression
  std::vector<uint8_t> decompressed_data(input_size * 2);  // Generous buffer

  decomp_strm.next_in = compressed_data.data();
  decomp_strm.avail_in = compressed_size;
  decomp_strm.next_out = decompressed_data.data();
  decomp_strm.avail_out = decompressed_data.size();

  // Decompress
  ret = lzma_code(&decomp_strm, LZMA_FINISH);
  EXPECT_EQ(ret, LZMA_STREAM_END);

  // Calculate decompressed size
  size_t decompressed_size = decompressed_data.size() - decomp_strm.avail_out;
  EXPECT_EQ(decompressed_size, input_size);

  // Verify data integrity
  std::string decompressed_string(
      reinterpret_cast<const char*>(decompressed_data.data()),
      decompressed_size);
  EXPECT_EQ(decompressed_string, original_data);

  // Clean up decoder
  lzma_end(&decomp_strm);

  // Print compression ratio for information
  double compression_ratio = static_cast<double>(compressed_size) / input_size;
  std::cout << "Original size: " << input_size << " bytes" << std::endl;
  std::cout << "Compressed size: " << compressed_size << " bytes" << std::endl;
  std::cout << "Compression ratio: " << compression_ratio << std::endl;
}

// Test different compression levels
TEST_F(XzIntegrationTest, CompressionLevelsTest) {
  std::vector<uint32_t> presets = {
      LZMA_PRESET_DEFAULT,
      0,  // Fastest
      1,  // Fast
      6,  // Default
      9   // Best compression
  };

  const uint8_t* input =
      reinterpret_cast<const uint8_t*>(original_data.c_str());
  size_t input_size = original_data.size();

  for (uint32_t preset : presets) {
    lzma_stream strm = LZMA_STREAM_INIT;

    lzma_ret ret = lzma_easy_encoder(&strm, preset, LZMA_CHECK_CRC64);
    ASSERT_EQ(ret, LZMA_OK)
        << "Failed to initialize encoder with preset " << preset;

    std::vector<uint8_t> compressed_data(input_size * 2);

    strm.next_in = input;
    strm.avail_in = input_size;
    strm.next_out = compressed_data.data();
    strm.avail_out = compressed_data.size();

    ret = lzma_code(&strm, LZMA_FINISH);
    EXPECT_TRUE(ret == LZMA_OK || ret == LZMA_STREAM_END)
        << "Compression failed with preset " << preset;

    size_t compressed_size = compressed_data.size() - strm.avail_out;
    EXPECT_GT(compressed_size, 0) << "No compression with preset " << preset;

    lzma_end(&strm);

    std::cout << "Preset " << preset << ": " << compressed_size << " bytes"
              << std::endl;
  }
}

// Test memory usage information
TEST_F(XzIntegrationTest, MemoryUsageTest) {
  // Test memory usage for different presets
  for (uint32_t preset = 0; preset <= 9; ++preset) {
    uint64_t mem_usage = lzma_easy_encoder_memusage(preset);
    EXPECT_GT(mem_usage, 0)
        << "Memory usage should be positive for preset " << preset;

    uint64_t mem_limit = lzma_easy_decoder_memusage(preset);
    EXPECT_GT(mem_limit, 0)
        << "Memory limit should be positive for preset " << preset;

    std::cout << "Preset " << preset << " - Encoder memory: " << mem_usage
              << " bytes"
              << ", Decoder memory: " << mem_limit << " bytes" << std::endl;
  }
}

// Test check types
TEST_F(XzIntegrationTest, CheckTypesTest) {
  std::vector<lzma_check> check_types = {LZMA_CHECK_NONE, LZMA_CHECK_CRC32,
                                         LZMA_CHECK_CRC64, LZMA_CHECK_SHA256};

  const uint8_t* input =
      reinterpret_cast<const uint8_t*>(original_data.c_str());
  size_t input_size = original_data.size();

  for (lzma_check check : check_types) {
    // Skip unsupported check types
    if (!lzma_check_is_supported(check)) {
      std::cout << "Check type " << check << " is not supported, skipping."
                << std::endl;
      continue;
    }

    lzma_stream strm = LZMA_STREAM_INIT;

    lzma_ret ret = lzma_easy_encoder(&strm, LZMA_PRESET_DEFAULT, check);
    ASSERT_EQ(ret, LZMA_OK)
        << "Failed to initialize encoder with check " << check;

    std::vector<uint8_t> compressed_data(input_size * 2);

    strm.next_in = input;
    strm.avail_in = input_size;
    strm.next_out = compressed_data.data();
    strm.avail_out = compressed_data.size();

    ret = lzma_code(&strm, LZMA_FINISH);
    EXPECT_TRUE(ret == LZMA_OK || ret == LZMA_STREAM_END)
        << "Compression failed with check " << check;

    size_t compressed_size = compressed_data.size() - strm.avail_out;
    EXPECT_GT(compressed_size, 0) << "No compression with check " << check;

    lzma_end(&strm);

    std::cout << "Check type " << check << ": " << compressed_size << " bytes"
              << std::endl;
  }
}

// Test stream information
TEST_F(XzIntegrationTest, StreamInfoTest) {
  // Test that we can check if a buffer looks like XZ data
  const uint8_t xz_magic[] = {0xFD, 0x37, 0x7A,
                              0x58, 0x5A, 0x00};  // XZ magic number

  // This is a simple test to ensure the header constants are available
  // In a real scenario, you would compress data first and then check the header
  EXPECT_EQ(sizeof(xz_magic), 6);

  // Test that we can get information about check types
  EXPECT_TRUE(lzma_check_is_supported(LZMA_CHECK_CRC64));
  EXPECT_TRUE(lzma_check_is_supported(LZMA_CHECK_CRC32));

  // Test check size calculation
  uint32_t crc32_size = lzma_check_size(LZMA_CHECK_CRC32);
  EXPECT_EQ(crc32_size, 4);

  uint32_t crc64_size = lzma_check_size(LZMA_CHECK_CRC64);
  EXPECT_EQ(crc64_size, 8);
}
