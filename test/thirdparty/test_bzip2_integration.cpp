#include <bzlib.h>
#include <gtest/gtest.h>

#include <iostream>
#include <string>
#include <vector>

class Bzip2IntegrationTest : public ::testing::Test {
 protected:
  void SetUp() override {}
  void TearDown() override {}
};

TEST_F(Bzip2IntegrationTest, CompressionDecompression) {
  // Test data
  std::string original_data =
      "Hello, world! This is a test for bzip2 compression.";

  // Prepare compression - allocate much more space for compression
  std::vector<char> compressed_data(original_data.size() *
                                    10);  // Much larger buffer
  unsigned int compressed_size = compressed_data.size();

  // Compress data
  int result = BZ2_bzBuffToBuffCompress(
      compressed_data.data(), &compressed_size,
      const_cast<char*>(original_data.data()), original_data.size(), 9, 0,
      30  // blockSize100k=9, verbosity=0, workFactor=30
  );

  std::cout << "Compression result: " << result
            << ", compressed size: " << compressed_size << std::endl;
  EXPECT_EQ(result, BZ_OK) << "Compression failed with error code: " << result;

  // Prepare decompression - allocate space for decompressed data
  std::vector<char> decompressed_data(original_data.size() * 2);
  unsigned int decompressed_size = decompressed_data.size();

  // Decompress data
  result = BZ2_bzBuffToBuffDecompress(
      decompressed_data.data(), &decompressed_size, compressed_data.data(),
      compressed_size, 0, 0  // small=0, verbosity=0
  );

  std::cout << "Decompression result: " << result
            << ", decompressed size: " << decompressed_size << std::endl;
  EXPECT_EQ(result, BZ_OK) << "Decompression failed with error code: "
                           << result;

  // Compare original and decompressed data
  std::string decompressed_string(decompressed_data.data(), decompressed_size);
  EXPECT_EQ(original_data, decompressed_string);
}
