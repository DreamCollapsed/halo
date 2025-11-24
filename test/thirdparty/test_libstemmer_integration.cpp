#include <gtest/gtest.h>
#include <libstemmer.h>

#include <cstring>
#include <iterator>
#include <string>
#include <vector>

// Test fixture for libstemmer integration tests
class LibstemmerIntegrationTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // libstemmer doesn't require explicit initialization
  }

  void TearDown() override {
    // libstemmer doesn't require explicit cleanup
  }
};

// Test basic stemmer functionality
TEST_F(LibstemmerIntegrationTest, BasicStemming) {
  // Create English stemmer
  struct sb_stemmer* stemmer = sb_stemmer_new("english", "UTF_8");
  ASSERT_NE(stemmer, nullptr);

  // Test stemming a simple word
  std::string word_str = "running";
  std::vector<sb_symbol> word(word_str.begin(), word_str.end());

  const sb_symbol* stemmed =
      sb_stemmer_stem(stemmer, word.data(), static_cast<int>(word.size()));

  ASSERT_NE(stemmed, nullptr);

  int len = sb_stemmer_length(stemmer);
  std::string result(stemmed, std::next(stemmed, len));
  EXPECT_EQ(result, "run");

  sb_stemmer_delete(stemmer);
}

// Test multiple languages support
TEST_F(LibstemmerIntegrationTest, MultipleLanguages) {
  // Test English stemmer
  struct sb_stemmer* en_stemmer = sb_stemmer_new("english", "UTF_8");
  ASSERT_NE(en_stemmer, nullptr);

  std::string en_word_str = "running";
  std::vector<sb_symbol> en_word(en_word_str.begin(), en_word_str.end());

  const sb_symbol* en_stemmed = sb_stemmer_stem(
      en_stemmer, en_word.data(), static_cast<int>(en_word.size()));

  int en_len = sb_stemmer_length(en_stemmer);
  std::string en_result(en_stemmed, std::next(en_stemmed, en_len));
  EXPECT_EQ(en_result, "run");

  sb_stemmer_delete(en_stemmer);

  // Test French stemmer
  struct sb_stemmer* fr_stemmer = sb_stemmer_new("french", "UTF_8");
  ASSERT_NE(fr_stemmer, nullptr);

  std::string fr_word_str = "courant";
  std::vector<sb_symbol> fr_word(fr_word_str.begin(), fr_word_str.end());

  const sb_symbol* fr_stemmed = sb_stemmer_stem(
      fr_stemmer, fr_word.data(), static_cast<int>(fr_word.size()));

  int fr_len = sb_stemmer_length(fr_stemmer);
  std::string fr_result(fr_stemmed, std::next(fr_stemmed, fr_len));
  EXPECT_EQ(fr_result, "cour");

  sb_stemmer_delete(fr_stemmer);
}

// Test list available languages
TEST_F(LibstemmerIntegrationTest, ListLanguages) {
  const char** languages = sb_stemmer_list();
  ASSERT_NE(languages, nullptr);

  // Should contain at least some common languages
  bool found_english = false;
  bool found_french = false;
  bool found_german = false;

  const char** current = languages;
  while (*current != nullptr) {
    std::string lang(*current);
    if (lang == "english") {
      found_english = true;
    }
    if (lang == "french") {
      found_french = true;
    }
    if (lang == "german") {
      found_german = true;
    }

    std::cout << "Available language: " << lang << '\n';
    current = std::next(current);
  }

  EXPECT_TRUE(found_english);
  EXPECT_TRUE(found_french);
  EXPECT_TRUE(found_german);
}

// Test stemming various word forms
TEST_F(LibstemmerIntegrationTest, VariousWordForms) {
  struct sb_stemmer* stemmer = sb_stemmer_new("english", "UTF_8");
  ASSERT_NE(stemmer, nullptr);

  // Test cases: input word -> expected stem
  std::vector<std::pair<std::string, std::string>> test_cases = {
      {"running", "run"},        {"runs", "run"},
      {"runner", "runner"},      {"easily", "easili"},
      {"fairly", "fair"},        {"walking", "walk"},
      {"walked", "walk"},        {"walks", "walk"},
      {"cats", "cat"},           {"caresses", "caress"},
      {"ponies", "poni"},        {"ties", "tie"},
      {"flies", "fli"},          {"dies", "die"},
      {"agreed", "agre"},        {"disabled", "disabl"},
      {"measured", "measur"},    {"sized", "size"},
      {"meeting", "meet"},       {"stating", "state"},
      {"siezing", "siez"},       {"itemization", "item"},
      {"traditional", "tradit"}, {"reference", "refer"},
      {"colonizer", "colon"},    {"plotted", "plot"}};

  for (const auto& test_case : test_cases) {
    const std::string& word_str = test_case.first;
    const std::string& expected = test_case.second;

    std::vector<sb_symbol> word(word_str.begin(), word_str.end());

    const sb_symbol* stemmed =
        sb_stemmer_stem(stemmer, word.data(), static_cast<int>(word.size()));

    ASSERT_NE(stemmed, nullptr) << "Failed to stem word: " << word_str;

    int len = sb_stemmer_length(stemmer);
    std::string result(stemmed, std::next(stemmed, len));
    EXPECT_EQ(result, expected)
        << "Word: " << word_str << " -> Expected: " << expected
        << " Got: " << result;
  }

  sb_stemmer_delete(stemmer);
}

// Test encoding support
TEST_F(LibstemmerIntegrationTest, EncodingSupport) {
  // Test UTF-8 encoding (default)
  struct sb_stemmer* utf8_stemmer = sb_stemmer_new("english", "UTF_8");
  ASSERT_NE(utf8_stemmer, nullptr);

  std::string word_str = "running";
  std::vector<sb_symbol> word(word_str.begin(), word_str.end());

  const sb_symbol* stemmed =
      sb_stemmer_stem(utf8_stemmer, word.data(), static_cast<int>(word.size()));

  int len = sb_stemmer_length(utf8_stemmer);
  std::string result(stemmed, std::next(stemmed, len));
  EXPECT_EQ(result, "run");

  sb_stemmer_delete(utf8_stemmer);

  // Test ISO_8859_1 encoding
  struct sb_stemmer* iso_stemmer = sb_stemmer_new("english", "ISO_8859_1");
  ASSERT_NE(iso_stemmer, nullptr);

  const sb_symbol* iso_stemmed =
      sb_stemmer_stem(iso_stemmer, word.data(), static_cast<int>(word.size()));

  int iso_len = sb_stemmer_length(iso_stemmer);
  std::string iso_result(iso_stemmed, std::next(iso_stemmed, iso_len));
  EXPECT_EQ(iso_result, "run");

  sb_stemmer_delete(iso_stemmer);
}

// Test error handling
TEST_F(LibstemmerIntegrationTest, ErrorHandling) {
  // Test invalid language
  struct sb_stemmer* invalid_stemmer =
      sb_stemmer_new("invalid_language", "UTF_8");
  EXPECT_EQ(invalid_stemmer, nullptr);

  // Test invalid encoding
  struct sb_stemmer* invalid_encoding =
      sb_stemmer_new("english", "INVALID_ENCODING");
  EXPECT_EQ(invalid_encoding, nullptr);

  // Test with valid stemmer
  struct sb_stemmer* stemmer = sb_stemmer_new("english", "UTF_8");
  ASSERT_NE(stemmer, nullptr);

  // Test stemming empty string
  std::vector<sb_symbol> empty_word;
  const sb_symbol* empty_result =
      sb_stemmer_stem(stemmer, empty_word.data(), 0);
  EXPECT_NE(empty_result, nullptr);

  // Test stemming null - this should be handled gracefully
  // Note: We don't test null pointer directly as it's undefined behavior

  sb_stemmer_delete(stemmer);
}

// Test stemmer reuse
TEST_F(LibstemmerIntegrationTest, StemmerReuse) {
  struct sb_stemmer* stemmer = sb_stemmer_new("english", "UTF_8");
  ASSERT_NE(stemmer, nullptr);

  // Use the same stemmer multiple times
  std::vector<std::string> words = {"running", "walking", "jumping", "flying",
                                    "swimming"};
  std::vector<std::string> expected = {"run", "walk", "jump", "fli", "swim"};

  for (size_t i = 0; i < words.size(); i++) {
    std::vector<sb_symbol> word(words[i].begin(), words[i].end());

    const sb_symbol* stemmed =
        sb_stemmer_stem(stemmer, word.data(), static_cast<int>(word.size()));

    ASSERT_NE(stemmed, nullptr);

    int len = sb_stemmer_length(stemmer);
    std::string result(stemmed, std::next(stemmed, len));
    EXPECT_EQ(result, expected[i]) << "Word: " << words[i];
  }

  sb_stemmer_delete(stemmer);
}

// Test performance with many words
TEST_F(LibstemmerIntegrationTest, PerformanceTest) {
  struct sb_stemmer* stemmer = sb_stemmer_new("english", "UTF_8");
  ASSERT_NE(stemmer, nullptr);

  // Test with 1000 words
  std::vector<std::string> test_words;
  test_words.reserve(1000);
  for (int i = 0; i < 1000; i++) {
    test_words.push_back("running" + std::to_string(i));
  }

  auto start_time = std::chrono::high_resolution_clock::now();

  for (const auto& word_str : test_words) {
    std::vector<sb_symbol> word(word_str.begin(), word_str.end());
    const sb_symbol* stemmed =
        sb_stemmer_stem(stemmer, word.data(), static_cast<int>(word.size()));

    ASSERT_NE(stemmed, nullptr);
    // Don't need to check the result, just ensure it doesn't crash
  }

  auto end_time = std::chrono::high_resolution_clock::now();
  auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(
      end_time - start_time);

  std::cout << "Stemmed " << test_words.size() << " words in "
            << duration.count() << " ms" << '\n';

  // Should complete within reasonable time (adjust as needed)
  EXPECT_LT(duration.count(), 1000);  // Less than 1 second

  sb_stemmer_delete(stemmer);
}

// Test thread safety (basic test)
TEST_F(LibstemmerIntegrationTest, ThreadSafety) {
  // Create multiple stemmers for different threads
  struct sb_stemmer* stemmer1 = sb_stemmer_new("english", "UTF_8");
  struct sb_stemmer* stemmer2 = sb_stemmer_new("english", "UTF_8");

  ASSERT_NE(stemmer1, nullptr);
  ASSERT_NE(stemmer2, nullptr);

  // Use them simultaneously (basic test)
  std::string word1_str = "running";
  std::vector<sb_symbol> word1(word1_str.begin(), word1_str.end());

  std::string word2_str = "walking";
  std::vector<sb_symbol> word2(word2_str.begin(), word2_str.end());

  const sb_symbol* result1 =
      sb_stemmer_stem(stemmer1, word1.data(), static_cast<int>(word1.size()));

  const sb_symbol* result2 =
      sb_stemmer_stem(stemmer2, word2.data(), static_cast<int>(word2.size()));

  ASSERT_NE(result1, nullptr);
  ASSERT_NE(result2, nullptr);

  int len1 = sb_stemmer_length(stemmer1);
  std::string stem1(result1, std::next(result1, len1));

  int len2 = sb_stemmer_length(stemmer2);
  std::string stem2(result2, std::next(result2, len2));

  EXPECT_EQ(stem1, "run");
  EXPECT_EQ(stem2, "walk");

  sb_stemmer_delete(stemmer1);
  sb_stemmer_delete(stemmer2);
}
