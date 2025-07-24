#include <gtest/gtest.h>
#include <zlib.h>

#include <cstring>
#include <string>
#include <vector>

class ZlibIntegrationTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // Test data for compression/decompression
    original_data =
        "Hello, World! This is a test string for zlib compression. "
        "It should be long enough to show compression benefits. "
        "Zlib is a software library used for data compression. "
        "It was written by Jean-loup Gailly and Mark Adler and is "
        "an abstraction of the DEFLATE compression algorithm used in "
        "their gzip file compression program.";
  }

  std::string original_data;
};

// Test zlib version information
TEST_F(ZlibIntegrationTest, ZlibVersionTest) {
  // Test that zlib version is available
  const char* version = zlibVersion();
  ASSERT_NE(version, nullptr) << "zlib version should be available";

  // Check that version contains expected version number (1.3.1)
  std::string version_str(version);
  EXPECT_TRUE(version_str.find("1.3") != std::string::npos)
      << "Version: " << version_str;

  // Test version consistency
  EXPECT_EQ(ZLIB_VERSION[0], version[0]) << "Major version should match";
}

// Test basic compression and decompression
TEST_F(ZlibIntegrationTest, BasicCompressionTest) {
  // Prepare source data
  const char* source = original_data.c_str();
  uLong source_len = original_data.length();

  // Calculate destination buffer size
  uLong dest_len = compressBound(source_len);
  std::vector<Bytef> dest(dest_len);

  // Compress the data
  int result = compress(dest.data(), &dest_len,
                        reinterpret_cast<const Bytef*>(source), source_len);

  EXPECT_EQ(result, Z_OK) << "Compression should succeed";
  EXPECT_LT(dest_len, source_len)
      << "Compressed size should be smaller than original";

  // Test decompression
  uLong decomp_len = source_len;
  std::vector<Bytef> decomp(decomp_len);

  result = uncompress(decomp.data(), &decomp_len, dest.data(), dest_len);

  EXPECT_EQ(result, Z_OK) << "Decompression should succeed";
  EXPECT_EQ(decomp_len, source_len)
      << "Decompressed size should match original";

  // Verify decompressed data matches original
  std::string decompressed(reinterpret_cast<char*>(decomp.data()), decomp_len);
  EXPECT_EQ(decompressed, original_data)
      << "Decompressed data should match original";
}

// Test different compression levels
TEST_F(ZlibIntegrationTest, CompressionLevelsTest) {
  const char* source = original_data.c_str();
  uLong source_len = original_data.length();

  struct CompressionResult {
    int level;
    uLong compressed_size;
    int result_code;
  };

  std::vector<CompressionResult> results;

  // Test different compression levels
  for (int level = Z_BEST_SPEED; level <= Z_BEST_COMPRESSION; level += 3) {
    uLong dest_len = compressBound(source_len);
    std::vector<Bytef> dest(dest_len);

    int result =
        compress2(dest.data(), &dest_len,
                  reinterpret_cast<const Bytef*>(source), source_len, level);

    results.push_back({level, dest_len, result});

    EXPECT_EQ(result, Z_OK)
        << "Compression level " << level << " should succeed";
  }

  // Verify that higher compression levels generally produce smaller sizes
  // (though this isn't guaranteed for all data)
  EXPECT_FALSE(results.empty()) << "Should have compression results";

  // Test that all compressions produced valid results
  for (const auto& res : results) {
    EXPECT_EQ(res.result_code, Z_OK)
        << "Compression level " << res.level << " should succeed";
    EXPECT_GT(res.compressed_size, 0) << "Compressed size should be positive";
    EXPECT_LT(res.compressed_size, source_len)
        << "Compressed size should be smaller than original";
  }
}

// Test streaming compression/decompression
TEST_F(ZlibIntegrationTest, StreamingCompressionTest) {
  const char* source = original_data.c_str();
  uLong source_len = original_data.length();

  // Initialize compression stream
  z_stream strm;
  memset(&strm, 0, sizeof(strm));

  int result = deflateInit(&strm, Z_DEFAULT_COMPRESSION);
  ASSERT_EQ(result, Z_OK) << "deflateInit should succeed";

  // Prepare buffers
  std::vector<Bytef> compressed_data;
  const size_t chunk_size = 256;
  std::vector<Bytef> output_buffer(chunk_size);

  // Set up input
  strm.avail_in = source_len;
  strm.next_in = reinterpret_cast<Bytef*>(const_cast<char*>(source));

  // Compress data
  do {
    strm.avail_out = chunk_size;
    strm.next_out = output_buffer.data();

    result = deflate(&strm, Z_FINISH);
    EXPECT_TRUE(result == Z_OK || result == Z_STREAM_END)
        << "deflate should succeed or signal end";

    size_t have = chunk_size - strm.avail_out;
    compressed_data.insert(compressed_data.end(), output_buffer.begin(),
                           output_buffer.begin() + have);
  } while (strm.avail_out == 0);

  EXPECT_EQ(result, Z_STREAM_END) << "Compression should complete";

  // Clean up compression stream
  result = deflateEnd(&strm);
  EXPECT_EQ(result, Z_OK) << "deflateEnd should succeed";

  // Test decompression
  memset(&strm, 0, sizeof(strm));
  result = inflateInit(&strm);
  ASSERT_EQ(result, Z_OK) << "inflateInit should succeed";

  std::vector<Bytef> decompressed_data;

  strm.avail_in = compressed_data.size();
  strm.next_in = compressed_data.data();

  do {
    strm.avail_out = chunk_size;
    strm.next_out = output_buffer.data();

    result = inflate(&strm, Z_NO_FLUSH);
    EXPECT_TRUE(result == Z_OK || result == Z_STREAM_END)
        << "inflate should succeed or signal end";

    size_t have = chunk_size - strm.avail_out;
    decompressed_data.insert(decompressed_data.end(), output_buffer.begin(),
                             output_buffer.begin() + have);
  } while (strm.avail_out == 0);

  EXPECT_EQ(result, Z_STREAM_END) << "Decompression should complete";

  // Clean up decompression stream
  result = inflateEnd(&strm);
  EXPECT_EQ(result, Z_OK) << "inflateEnd should succeed";

  // Verify decompressed data
  EXPECT_EQ(decompressed_data.size(), source_len)
      << "Decompressed size should match original";

  std::string decompressed(reinterpret_cast<char*>(decompressed_data.data()),
                           decompressed_data.size());
  EXPECT_EQ(decompressed, original_data)
      << "Decompressed data should match original";
}

// Test CRC32 functionality
TEST_F(ZlibIntegrationTest, CRC32Test) {
  const char* data = original_data.c_str();
  uLong len = original_data.length();

  // Calculate CRC32
  uLong crc = crc32(0L, Z_NULL, 0);
  crc = crc32(crc, reinterpret_cast<const Bytef*>(data), len);

  EXPECT_NE(crc, 0) << "CRC32 should not be zero for non-empty data";

  // Test CRC32 consistency
  uLong crc2 = crc32(0L, Z_NULL, 0);
  crc2 = crc32(crc2, reinterpret_cast<const Bytef*>(data), len);

  EXPECT_EQ(crc, crc2) << "CRC32 should be consistent";

  // Test incremental CRC32
  uLong crc_incremental = crc32(0L, Z_NULL, 0);
  size_t half_len = len / 2;

  crc_incremental =
      crc32(crc_incremental, reinterpret_cast<const Bytef*>(data), half_len);
  crc_incremental =
      crc32(crc_incremental, reinterpret_cast<const Bytef*>(data + half_len),
            len - half_len);

  EXPECT_EQ(crc, crc_incremental)
      << "Incremental CRC32 should match full CRC32";
}

// Test error handling
TEST_F(ZlibIntegrationTest, ErrorHandlingTest) {
  // Test compression with invalid parameters
  uLong dest_len = 0;  // Too small buffer
  Bytef dest;

  const char* source = "test";
  uLong source_len = 4;

  int result = compress(&dest, &dest_len,
                        reinterpret_cast<const Bytef*>(source), source_len);

  EXPECT_EQ(result, Z_BUF_ERROR)
      << "Should return buffer error for too small buffer";

  // Test decompression with invalid data
  dest_len = 100;
  std::vector<Bytef> dest_buf(dest_len);
  std::vector<Bytef> invalid_data = {0xFF, 0xFF, 0xFF,
                                     0xFF};  // Invalid compressed data

  result = uncompress(dest_buf.data(), &dest_len, invalid_data.data(),
                      invalid_data.size());

  EXPECT_NE(result, Z_OK) << "Should fail on invalid compressed data";
}

// Test feature support and constants
TEST_F(ZlibIntegrationTest, FeatureSupportTest) {
  // Test that expected constants are defined
  EXPECT_GE(Z_OK, 0) << "Z_OK should be defined and non-negative";
  EXPECT_LT(Z_STREAM_ERROR, 0) << "Z_STREAM_ERROR should be negative";
  EXPECT_LT(Z_DATA_ERROR, 0) << "Z_DATA_ERROR should be negative";
  EXPECT_LT(Z_MEM_ERROR, 0) << "Z_MEM_ERROR should be negative";
  EXPECT_LT(Z_BUF_ERROR, 0) << "Z_BUF_ERROR should be negative";

  // Test compression level constants
  EXPECT_GE(Z_BEST_SPEED, 1) << "Z_BEST_SPEED should be at least 1";
  EXPECT_LE(Z_BEST_COMPRESSION, 9) << "Z_BEST_COMPRESSION should be at most 9";
  EXPECT_LT(Z_BEST_SPEED, Z_BEST_COMPRESSION)
      << "Speed should be less than best compression";

  // Test that zlib was compiled with expected features
  const char* version = zlibVersion();
  EXPECT_NE(version, nullptr) << "Version should be available";

  // Test compressBound function
  uLong test_size = 1000;
  uLong bound = compressBound(test_size);
  EXPECT_GT(bound, test_size)
      << "Compression bound should be larger than source size";
  EXPECT_LT(bound, test_size * 2) << "Compression bound should be reasonable";
}
