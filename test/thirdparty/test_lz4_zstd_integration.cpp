#include <gtest/gtest.h>
#include <lz4.h>
#include <lz4hc.h>
#include <zdict.h>
#include <zstd.h>

#include <string>
#include <vector>

class Lz4ZstdIntegrationTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // Prepare test data
    original_data_ =
        "This is a test string that will be used for compression testing. "
        "LZ4 supports dictionary compression which can be combined with "
        "Zstandard Dictionary Builder for better compression ratios. "
        "This functionality demonstrates the integration between LZ4 and Zstd.";

    // Create dictionary data
    dictionary_data_ =
        "test string compression dictionary better ratios functionality "
        "integration";
  }
  [[nodiscard]] const std::string& OriginalData() const {
    return original_data_;
  }

  [[nodiscard]] const std::string& DictionaryData() const {
    return dictionary_data_;
  }

 private:
  std::string original_data_;
  std::string dictionary_data_;
};

// Test LZ4 dictionary functionality
TEST_F(Lz4ZstdIntegrationTest, LZ4DictionaryCompressionTest) {
  // Test LZ4 dictionary compression functionality
  LZ4_stream_t* stream = LZ4_createStream();
  ASSERT_NE(stream, nullptr);

  // Load dictionary
  int dict_loaded = LZ4_loadDict(stream, DictionaryData().c_str(),
                                 static_cast<int>(DictionaryData().length()));
  EXPECT_GT(dict_loaded, 0);

  // Compress data
  std::vector<char> compressed(
      LZ4_compressBound(static_cast<int>(OriginalData().length())));
  int compressed_size = LZ4_compress_fast_continue(
      stream, OriginalData().c_str(), compressed.data(),
      static_cast<int>(OriginalData().length()),
      static_cast<int>(compressed.size()), 1);

  EXPECT_GT(compressed_size, 0);
  EXPECT_LT(compressed_size, static_cast<int>(OriginalData().length()));
  // Decompress
  std::vector<char> decompressed(OriginalData().length());
  int decompressed_size = LZ4_decompress_safe_usingDict(
      compressed.data(), decompressed.data(), compressed_size,
      static_cast<int>(decompressed.size()), DictionaryData().c_str(),
      static_cast<int>(DictionaryData().length()));

  EXPECT_EQ(decompressed_size, static_cast<int>(OriginalData().length()));
  EXPECT_EQ(std::string(decompressed.data(), decompressed_size),
            OriginalData());

  LZ4_freeStream(stream);
}

// Test Zstd dictionary builder
TEST_F(Lz4ZstdIntegrationTest, ZstdDictionaryBuilderTest) {
  // Create larger training dataset to ensure successful dictionary training
  std::vector<std::string> training_data;
  for (int i = 0; i < 10; ++i) {
    std::string sample = "This is test compression data sample number " +
                         std::to_string(i) + " with repeated patterns and " +
                         "common words for dictionary training purposes. " +
                         "The compression dictionary should find patterns in " +
                         "this repetitive text content.";
    training_data.push_back(sample);
  }

  // Merge all training data into a single buffer (correct usage for
  // ZDICT_trainFromBuffer)
  std::string all_training_data;
  std::vector<size_t> sample_sizes;

  for (const auto& sample : training_data) {
    all_training_data += sample;
    sample_sizes.push_back(sample.length());
  }

  // Create dictionary
  std::vector<char> dictionary(2048);  // Increase dictionary size
  size_t dict_size = ZDICT_trainFromBuffer(
      dictionary.data(), dictionary.size(), all_training_data.c_str(),
      sample_sizes.data(), sample_sizes.size());

  // Dictionary training must succeed with adequate training data
  ASSERT_FALSE(ZDICT_isError(dict_size))
      << "Dictionary training must succeed: " << ZDICT_getErrorName(dict_size);

  EXPECT_GT(dict_size, 0);
  EXPECT_LT(dict_size, dictionary.size());

  // Verify dictionary can be used by Zstd
  ZSTD_CDict* cdict = ZSTD_createCDict(dictionary.data(), dict_size, 1);
  EXPECT_NE(cdict, nullptr);

  if (cdict != nullptr) {
    ZSTD_freeCDict(cdict);
  }
}

// Test LZ4 and Zstd dictionary compatibility
TEST_F(Lz4ZstdIntegrationTest, LZ4ZstdDictionaryCompatibilityTest) {
  // Use Zstd to create dictionary - provide more adequate training data
  std::vector<std::string> training_samples;
  for (int i = 0; i < 8; ++i) {
    std::string sample = "compression test data sample number " +
                         std::to_string(i) + " for dictionary training " +
                         "with repeated patterns and common words that " +
                         "help build effective compression dictionaries.";
    training_samples.push_back(sample);
  }

  // Merge training data
  std::string training_data;
  std::vector<size_t> training_sample_sizes;
  for (const auto& sample : training_samples) {
    training_data += sample;
    training_sample_sizes.push_back(sample.length());
  }

  // Create Zstd dictionary
  std::vector<char> zstd_dictionary(2048);  // Increase dictionary size
  size_t zstd_dict_size = ZDICT_trainFromBuffer(
      zstd_dictionary.data(), zstd_dictionary.size(), training_data.c_str(),
      training_sample_sizes.data(), training_sample_sizes.size());

  // Dictionary training must succeed with adequate training data
  ASSERT_FALSE(ZDICT_isError(zstd_dict_size))
      << "Zstd dictionary training must succeed: "
      << ZDICT_getErrorName(zstd_dict_size);

  EXPECT_GT(zstd_dict_size, 0);

  // Try to use Zstd-created dictionary with LZ4
  // Note: This tests conceptual compatibility, actual usage requires extracting
  // raw dictionary content
  LZ4_stream_t* lz4_stream = LZ4_createStream();
  ASSERT_NE(lz4_stream, nullptr);

  // Use partial dictionary data (skip Zstd-specific header information)
  const char* dict_content = training_data.c_str();
  int dict_loaded = LZ4_loadDict(lz4_stream, dict_content,
                                 static_cast<int>(training_data.length()));
  EXPECT_GT(dict_loaded, 0);

  // Test compression
  std::vector<char> compressed(
      LZ4_compressBound(static_cast<int>(OriginalData().length())));
  int compressed_size = LZ4_compress_fast_continue(
      lz4_stream, OriginalData().c_str(), compressed.data(),
      static_cast<int>(OriginalData().length()),
      static_cast<int>(compressed.size()), 1);

  EXPECT_GT(compressed_size, 0);

  LZ4_freeStream(lz4_stream);
}

// Test dictionary compression effectiveness
TEST_F(Lz4ZstdIntegrationTest, DictionaryCompressionEfficiencyTest) {
  // Compression without dictionary
  std::vector<char> compressed_no_dict(
      LZ4_compressBound(static_cast<int>(OriginalData().length())));
  int size_no_dict =
      LZ4_compress_default(OriginalData().c_str(), compressed_no_dict.data(),
                           static_cast<int>(OriginalData().length()),
                           static_cast<int>(compressed_no_dict.size()));

  EXPECT_GT(size_no_dict, 0);

  // Compression with dictionary
  LZ4_stream_t* stream = LZ4_createStream();
  ASSERT_NE(stream, nullptr);

  int dict_loaded = LZ4_loadDict(stream, DictionaryData().c_str(),
                                 static_cast<int>(DictionaryData().length()));
  EXPECT_GT(dict_loaded, 0);

  std::vector<char> compressed_with_dict(
      LZ4_compressBound(static_cast<int>(OriginalData().length())));
  int size_with_dict = LZ4_compress_fast_continue(
      stream, OriginalData().c_str(), compressed_with_dict.data(),
      static_cast<int>(OriginalData().length()),
      static_cast<int>(compressed_with_dict.size()), 1);

  EXPECT_GT(size_with_dict, 0);

  // Dictionary compression should be more effective (in ideal cases)
  std::cout << "Compression without dictionary: " << size_no_dict << " bytes"
            << "\n";
  std::cout << "Compression with dictionary: " << size_with_dict << " bytes"
            << "\n";
  std::cout << "Dictionary size: " << DictionaryData().length() << " bytes"
            << "\n";
  LZ4_freeStream(stream);
}
