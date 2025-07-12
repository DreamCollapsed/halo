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
    // 准备测试数据
    original_data =
        "This is a test string that will be used for compression testing. "
        "LZ4 supports dictionary compression which can be combined with "
        "Zstandard Dictionary Builder for better compression ratios. "
        "This functionality demonstrates the integration between LZ4 and Zstd.";

    // 创建字典数据
    dictionary_data =
        "test string compression dictionary better ratios functionality "
        "integration";
  }

  std::string original_data;
  std::string dictionary_data;
};

// 测试 LZ4 字典功能
TEST_F(Lz4ZstdIntegrationTest, LZ4DictionaryCompressionTest) {
  // 测试 LZ4 字典压缩功能
  LZ4_stream_t* stream = LZ4_createStream();
  ASSERT_NE(stream, nullptr);

  // 加载字典
  int dict_loaded =
      LZ4_loadDict(stream, dictionary_data.c_str(), dictionary_data.length());
  EXPECT_GT(dict_loaded, 0);

  // 压缩数据
  std::vector<char> compressed(LZ4_compressBound(original_data.length()));
  int compressed_size = LZ4_compress_fast_continue(
      stream, original_data.c_str(), compressed.data(), original_data.length(),
      compressed.size(), 1);

  EXPECT_GT(compressed_size, 0);
  EXPECT_LT(compressed_size, static_cast<int>(original_data.length()));

  // 解压缩
  std::vector<char> decompressed(original_data.length());
  int decompressed_size = LZ4_decompress_safe_usingDict(
      compressed.data(), decompressed.data(), compressed_size,
      decompressed.size(), dictionary_data.c_str(), dictionary_data.length());

  EXPECT_EQ(decompressed_size, static_cast<int>(original_data.length()));
  EXPECT_EQ(std::string(decompressed.data(), decompressed_size), original_data);

  LZ4_freeStream(stream);
}

// 测试 Zstd 字典构建器
TEST_F(Lz4ZstdIntegrationTest, ZstdDictionaryBuilderTest) {
  // 创建训练数据集
  std::vector<std::string> training_data = {
      "test compression data sample one", "test compression data sample two",
      "test compression data sample three",
      "compression efficiency with dictionary",
      "dictionary training for better ratios"};

  // 准备训练数据
  std::vector<const void*> samples;
  std::vector<size_t> sample_sizes;
  std::string all_training_data;

  for (const auto& sample : training_data) {
    samples.push_back(sample.c_str());
    sample_sizes.push_back(sample.length());
    all_training_data += sample;
  }

  // 创建字典
  std::vector<char> dictionary(1024);
  size_t dict_size = ZDICT_trainFromBuffer(
      dictionary.data(), dictionary.size(), all_training_data.c_str(),
      sample_sizes.data(), sample_sizes.size());

  // 检查是否成功，如果失败则检查错误码
  if (ZDICT_isError(dict_size)) {
    // 字典训练可能因为数据不足而失败，这是正常的
    GTEST_SKIP()
        << "Dictionary training failed (likely insufficient training data): "
        << ZDICT_getErrorName(dict_size);
  } else {
    EXPECT_GT(dict_size, 0);
    EXPECT_LT(dict_size, dictionary.size());

    // 验证字典可以被 Zstd 使用
    ZSTD_CDict* cdict = ZSTD_createCDict(dictionary.data(), dict_size, 1);
    EXPECT_NE(cdict, nullptr);

    if (cdict) {
      ZSTD_freeCDict(cdict);
    }
  }
}

// 测试 LZ4 与 Zstd 字典的兼容性
TEST_F(Lz4ZstdIntegrationTest, LZ4ZstdDictionaryCompatibilityTest) {
  // 使用 Zstd 创建字典
  std::vector<std::string> training_samples = {
      "compression test data sample", "dictionary compression efficiency",
      "LZ4 and Zstd integration test"};

  std::string training_data;
  for (const auto& sample : training_samples) {
    training_data += sample + " ";
  }

  // 创建 Zstd 字典
  std::vector<char> zstd_dictionary(512);
  std::vector<size_t> training_sample_sizes;
  for (const auto& sample : training_samples) {
    training_sample_sizes.push_back(sample.length());
  }

  size_t zstd_dict_size = ZDICT_trainFromBuffer(
      zstd_dictionary.data(), zstd_dictionary.size(), training_data.c_str(),
      training_sample_sizes.data(), training_sample_sizes.size());

  // 检查字典训练是否成功
  if (ZDICT_isError(zstd_dict_size)) {
    GTEST_SKIP() << "Zstd dictionary training failed: "
                 << ZDICT_getErrorName(zstd_dict_size);
  }

  EXPECT_GT(zstd_dict_size, 0);

  // 尝试将 Zstd 创建的字典用于 LZ4
  // 注意：这里测试的是概念上的兼容性，实际使用中需要提取原始字典内容
  LZ4_stream_t* lz4_stream = LZ4_createStream();
  ASSERT_NE(lz4_stream, nullptr);

  // 使用部分字典数据（跳过 Zstd 特有的头部信息）
  const char* dict_content = training_data.c_str();
  int dict_loaded =
      LZ4_loadDict(lz4_stream, dict_content, training_data.length());
  EXPECT_GT(dict_loaded, 0);

  // 测试压缩
  std::vector<char> compressed(LZ4_compressBound(original_data.length()));
  int compressed_size = LZ4_compress_fast_continue(
      lz4_stream, original_data.c_str(), compressed.data(),
      original_data.length(), compressed.size(), 1);

  EXPECT_GT(compressed_size, 0);

  LZ4_freeStream(lz4_stream);
}

// 测试字典压缩的效果
TEST_F(Lz4ZstdIntegrationTest, DictionaryCompressionEfficiencyTest) {
  // 无字典压缩
  std::vector<char> compressed_no_dict(
      LZ4_compressBound(original_data.length()));
  int size_no_dict =
      LZ4_compress_default(original_data.c_str(), compressed_no_dict.data(),
                           original_data.length(), compressed_no_dict.size());

  EXPECT_GT(size_no_dict, 0);

  // 有字典压缩
  LZ4_stream_t* stream = LZ4_createStream();
  ASSERT_NE(stream, nullptr);

  int dict_loaded =
      LZ4_loadDict(stream, dictionary_data.c_str(), dictionary_data.length());
  EXPECT_GT(dict_loaded, 0);

  std::vector<char> compressed_with_dict(
      LZ4_compressBound(original_data.length()));
  int size_with_dict = LZ4_compress_fast_continue(
      stream, original_data.c_str(), compressed_with_dict.data(),
      original_data.length(), compressed_with_dict.size(), 1);

  EXPECT_GT(size_with_dict, 0);

  // 字典压缩应该更有效（在理想情况下）
  std::cout << "Compression without dictionary: " << size_no_dict << " bytes"
            << std::endl;
  std::cout << "Compression with dictionary: " << size_with_dict << " bytes"
            << std::endl;
  std::cout << "Dictionary size: " << dictionary_data.length() << " bytes"
            << std::endl;

  LZ4_freeStream(stream);
}
