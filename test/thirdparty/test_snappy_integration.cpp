#include <gtest/gtest.h>
#include <snappy.h>

#include <cstring>
#include <numeric>
#include <string>
#include <vector>

class SnappyIntegrationTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // Generate test data
    test_data =
        "Hello, Snappy! This is a test string for compression. "
        "It contains some repetitive content to ensure good compression "
        "ratios. "
        "Repetitive content, repetitive content, repetitive content!";

    // Generate binary test data
    binary_data.resize(1024);
    std::iota(binary_data.begin(), binary_data.end(), 0);
  }

  std::string test_data;
  std::vector<uint8_t> binary_data;
};

// Test basic compression and decompression
TEST_F(SnappyIntegrationTest, BasicCompressionTest) {
  std::string compressed;
  std::string decompressed;

  // Compress
  size_t compressed_length =
      snappy::Compress(test_data.data(), test_data.size(), &compressed);
  ASSERT_GT(compressed_length, 0);
  EXPECT_LT(compressed.size(), test_data.size());  // Should be smaller

  // Decompress
  bool success =
      snappy::Uncompress(compressed.data(), compressed.size(), &decompressed);
  ASSERT_TRUE(success);
  EXPECT_EQ(decompressed, test_data);
}

// Test compression with raw buffer interface
TEST_F(SnappyIntegrationTest, RawBufferCompressionTest) {
  size_t max_compressed_length = snappy::MaxCompressedLength(test_data.size());
  std::vector<char> compressed(max_compressed_length);

  size_t compressed_length;
  snappy::RawCompress(test_data.data(), test_data.size(), compressed.data(),
                      &compressed_length);

  ASSERT_GT(compressed_length, 0);
  ASSERT_LE(compressed_length, max_compressed_length);

  // Decompress
  size_t uncompressed_length;
  bool valid = snappy::GetUncompressedLength(
      compressed.data(), compressed_length, &uncompressed_length);
  ASSERT_TRUE(valid);
  EXPECT_EQ(uncompressed_length, test_data.size());

  std::vector<char> decompressed(uncompressed_length);
  bool success = snappy::RawUncompress(compressed.data(), compressed_length,
                                       decompressed.data());
  ASSERT_TRUE(success);

  std::string result(decompressed.begin(), decompressed.end());
  EXPECT_EQ(result, test_data);
}

// Test binary data compression
TEST_F(SnappyIntegrationTest, BinaryDataCompressionTest) {
  std::string compressed;
  std::string decompressed;

  std::string binary_string(binary_data.begin(), binary_data.end());

  // Compress binary data
  snappy::Compress(binary_string.data(), binary_string.size(), &compressed);
  ASSERT_GT(compressed.size(), 0);

  // Decompress
  bool success =
      snappy::Uncompress(compressed.data(), compressed.size(), &decompressed);
  ASSERT_TRUE(success);
  EXPECT_EQ(decompressed, binary_string);

  // Verify byte-by-byte
  EXPECT_EQ(decompressed.size(), binary_data.size());
  for (size_t i = 0; i < binary_data.size(); ++i) {
    EXPECT_EQ(static_cast<uint8_t>(decompressed[i]), binary_data[i]);
  }
}

// Test validation functions
TEST_F(SnappyIntegrationTest, ValidationTest) {
  std::string compressed;
  snappy::Compress(test_data.data(), test_data.size(), &compressed);

  // Test valid compressed data
  EXPECT_TRUE(
      snappy::IsValidCompressedBuffer(compressed.data(), compressed.size()));

  // Test invalid compressed data
  std::string invalid_data = "This is not compressed data";
  EXPECT_FALSE(snappy::IsValidCompressedBuffer(invalid_data.data(),
                                               invalid_data.size()));

  // Test getting uncompressed length
  size_t uncompressed_length;
  bool valid = snappy::GetUncompressedLength(
      compressed.data(), compressed.size(), &uncompressed_length);
  ASSERT_TRUE(valid);
  EXPECT_EQ(uncompressed_length, test_data.size());
}

// Test empty data
TEST_F(SnappyIntegrationTest, EmptyDataTest) {
  std::string empty_data;
  std::string compressed;
  std::string decompressed;

  // Compress empty data
  snappy::Compress(empty_data.data(), empty_data.size(), &compressed);
  ASSERT_GT(compressed.size(), 0);  // Even empty data produces some output

  // Decompress
  bool success =
      snappy::Uncompress(compressed.data(), compressed.size(), &decompressed);
  ASSERT_TRUE(success);
  EXPECT_EQ(decompressed.size(), 0);
  EXPECT_EQ(decompressed, empty_data);
}

// Test large data compression
TEST_F(SnappyIntegrationTest, LargeDataTest) {
  // Generate larger test data
  std::string large_data;
  large_data.reserve(100000);
  for (int i = 0; i < 10000; ++i) {
    large_data += test_data;
  }

  std::string compressed;
  std::string decompressed;

  // Compress
  size_t compressed_length =
      snappy::Compress(large_data.data(), large_data.size(), &compressed);
  ASSERT_GT(compressed_length, 0);
  EXPECT_LT(compressed.size(),
            large_data.size());  // Should achieve good compression

  // Decompress
  bool success =
      snappy::Uncompress(compressed.data(), compressed.size(), &decompressed);
  ASSERT_TRUE(success);
  EXPECT_EQ(decompressed, large_data);
}

// Performance test
TEST_F(SnappyIntegrationTest, PerformanceTest) {
  // Generate test data
  std::string perf_data;
  perf_data.reserve(10000);
  for (int i = 0; i < 1000; ++i) {
    perf_data += test_data;
  }

  std::string compressed;
  std::string decompressed;

  auto start = std::chrono::high_resolution_clock::now();

  // Perform multiple compressions
  for (int i = 0; i < 100; ++i) {
    compressed.clear();
    snappy::Compress(perf_data.data(), perf_data.size(), &compressed);
  }

  auto end = std::chrono::high_resolution_clock::now();
  auto duration =
      std::chrono::duration_cast<std::chrono::milliseconds>(end - start);

  EXPECT_LT(duration.count(), 1000);  // Should complete in less than 1 second
  EXPECT_GT(compressed.size(), 0);

  // Test one decompression for correctness
  bool success =
      snappy::Uncompress(compressed.data(), compressed.size(), &decompressed);
  ASSERT_TRUE(success);
  EXPECT_EQ(decompressed, perf_data);
}

// Test error handling
TEST_F(SnappyIntegrationTest, ErrorHandlingTest) {
  std::string decompressed;

  // Try to decompress invalid data
  std::string invalid_compressed = "Invalid compressed data";
  bool success = snappy::Uncompress(invalid_compressed.data(),
                                    invalid_compressed.size(), &decompressed);
  EXPECT_FALSE(success);

  // Try to get uncompressed length from invalid data
  size_t uncompressed_length;
  bool valid = snappy::GetUncompressedLength(invalid_compressed.data(),
                                             invalid_compressed.size(),
                                             &uncompressed_length);
  // Note: Snappy may not detect all invalid data in length check
  // The main error detection happens during actual decompression
  (void)valid;  // Suppress unused variable warning if not checked
}

// Integration test with real-world scenario
TEST_F(SnappyIntegrationTest, RealWorldScenarioTest) {
  // Simulate compressing JSON-like data
  std::string json_like_data = R"({
        "users": [
            {"id": 1, "name": "Alice", "email": "alice@example.com"},
            {"id": 2, "name": "Bob", "email": "bob@example.com"},
            {"id": 3, "name": "Charlie", "email": "charlie@example.com"}
        ],
        "metadata": {
            "version": "1.0",
            "timestamp": "2025-01-13T10:30:00Z",
            "total_count": 3
        }
    })";

  // Repeat to simulate larger payloads
  std::string large_json;
  for (int i = 0; i < 100; ++i) {
    large_json += json_like_data;
  }

  std::string compressed;
  std::string decompressed;

  // Compress
  snappy::Compress(large_json.data(), large_json.size(), &compressed);

  // Check compression ratio
  double compression_ratio =
      static_cast<double>(compressed.size()) / large_json.size();
  EXPECT_LT(compression_ratio, 0.8);  // Should achieve at least 20% compression

  // Decompress and verify
  bool success =
      snappy::Uncompress(compressed.data(), compressed.size(), &decompressed);
  ASSERT_TRUE(success);
  EXPECT_EQ(decompressed, large_json);

  std::cout << "Original size: " << large_json.size() << " bytes" << std::endl;
  std::cout << "Compressed size: " << compressed.size() << " bytes"
            << std::endl;
  std::cout << "Compression ratio: " << compression_ratio << std::endl;
}
