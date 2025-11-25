#include <gtest/gtest.h>
#include <snappy.h>

#include <cstring>
#include <string>
#include <vector>

class SnappyIntegrationTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // Generate test data
    test_data_ =
        "Hello, Snappy! This is a test string for compression. "
        "It contains some repetitive content to ensure good compression "
        "ratios. "
        "Repetitive content, repetitive content, repetitive content!";

    // Generate binary test data
    binary_data_.resize(1024);
    for (size_t i = 0; i < binary_data_.size(); ++i) {
      binary_data_[i] = static_cast<uint8_t>(i % 256);
    }
  }

  [[nodiscard]] const std::string& TestData() const { return test_data_; }

  [[nodiscard]] const std::vector<uint8_t>& BinaryData() const {
    return binary_data_;
  }

 private:
  std::string test_data_;
  std::vector<uint8_t> binary_data_;
};

// Test version macros
TEST_F(SnappyIntegrationTest, VersionCheck) {
  EXPECT_EQ(SNAPPY_MAJOR, 1);
  EXPECT_EQ(SNAPPY_MINOR, 2);
  EXPECT_EQ(SNAPPY_PATCHLEVEL, 2);
  EXPECT_EQ(SNAPPY_VERSION, ((1 << 16) | (2 << 8) | 2));
}

// Test basic compression and decompression
TEST_F(SnappyIntegrationTest, BasicCompressionTest) {
  std::string compressed;
  std::string decompressed;

  // Compress
  size_t compressed_length =
      snappy::Compress(TestData().data(), TestData().size(), &compressed);
  ASSERT_GT(compressed_length, 0);
  EXPECT_LT(compressed.size(), TestData().size());  // Should be smaller

  // Decompress
  bool success =
      snappy::Uncompress(compressed.data(), compressed.size(), &decompressed);
  ASSERT_TRUE(success);
  EXPECT_EQ(decompressed, TestData());
}

// Test compression with raw buffer interface
TEST_F(SnappyIntegrationTest, RawBufferCompressionTest) {
  size_t max_compressed_length = snappy::MaxCompressedLength(TestData().size());
  std::vector<char> compressed(max_compressed_length);

  size_t compressed_length = 0;
  snappy::RawCompress(TestData().data(), TestData().size(), compressed.data(),
                      &compressed_length);

  ASSERT_GT(compressed_length, 0);
  ASSERT_LE(compressed_length, max_compressed_length);

  // Decompress
  size_t uncompressed_length = 0;
  bool valid = snappy::GetUncompressedLength(
      compressed.data(), compressed_length, &uncompressed_length);
  ASSERT_TRUE(valid);
  EXPECT_EQ(uncompressed_length, TestData().size());

  std::vector<char> decompressed(uncompressed_length);
  bool success = snappy::RawUncompress(compressed.data(), compressed_length,
                                       decompressed.data());
  ASSERT_TRUE(success);

  std::string result(decompressed.begin(), decompressed.end());
  EXPECT_EQ(result, TestData());
}

// Test binary data compression
TEST_F(SnappyIntegrationTest, BinaryDataCompressionTest) {
  std::string compressed;
  std::string decompressed;

  std::string binary_string(BinaryData().begin(), BinaryData().end());

  // Compress binary data
  snappy::Compress(binary_string.data(), binary_string.size(), &compressed);
  ASSERT_GT(compressed.size(), 0);

  // Decompress
  bool success =
      snappy::Uncompress(compressed.data(), compressed.size(), &decompressed);
  ASSERT_TRUE(success);
  EXPECT_EQ(decompressed, binary_string);

  // Verify byte-by-byte
  EXPECT_EQ(decompressed.size(), BinaryData().size());
  for (size_t i = 0; i < BinaryData().size(); ++i) {
    EXPECT_EQ(static_cast<uint8_t>(decompressed[i]), BinaryData()[i]);
  }
}

// Test validation functions
TEST_F(SnappyIntegrationTest, ValidationTest) {
  std::string compressed;
  snappy::Compress(TestData().data(), TestData().size(), &compressed);

  // Test valid compressed data
  EXPECT_TRUE(
      snappy::IsValidCompressedBuffer(compressed.data(), compressed.size()));

  // Test invalid compressed data
  std::string invalid_data = "This is not compressed data";
  EXPECT_FALSE(snappy::IsValidCompressedBuffer(invalid_data.data(),
                                               invalid_data.size()));

  // Test getting uncompressed length
  size_t uncompressed_length = 0;
  bool valid = snappy::GetUncompressedLength(
      compressed.data(), compressed.size(), &uncompressed_length);
  ASSERT_TRUE(valid);
  EXPECT_EQ(uncompressed_length, TestData().size());
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
    large_data += TestData();
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
    perf_data += TestData();
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
  size_t uncompressed_length = 0;
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
  double compression_ratio = static_cast<double>(compressed.size()) /
                             static_cast<double>(large_json.size());
  EXPECT_LT(compression_ratio, 0.8);  // Should achieve at least 20% compression

  // Decompress and verify
  bool success =
      snappy::Uncompress(compressed.data(), compressed.size(), &decompressed);
  ASSERT_TRUE(success);
  EXPECT_EQ(decompressed, large_json);

  std::cout << "Original size: " << large_json.size() << " bytes" << "\n";
  std::cout << "Compressed size: " << compressed.size() << " bytes"
            << "\n";
  std::cout << "Compression ratio: " << compression_ratio << "\n";
}
