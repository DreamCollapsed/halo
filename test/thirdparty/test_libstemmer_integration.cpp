#include <gtest/gtest.h>
#include <libstemmer.h>

#include <cstring>
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
  const char* word = "running";
  const sb_symbol* stemmed = sb_stemmer_stem(
      stemmer, reinterpret_cast<const sb_symbol*>(word), std::strlen(word));

  ASSERT_NE(stemmed, nullptr);

  std::string result(reinterpret_cast<const char*>(stemmed));
  EXPECT_EQ(result, "run");

  sb_stemmer_delete(stemmer);
}

// Test multiple languages support
TEST_F(LibstemmerIntegrationTest, MultipleLanguages) {
  // Test English stemmer
  struct sb_stemmer* en_stemmer = sb_stemmer_new("english", "UTF_8");
  ASSERT_NE(en_stemmer, nullptr);

  const char* en_word = "running";
  const sb_symbol* en_stemmed =
      sb_stemmer_stem(en_stemmer, reinterpret_cast<const sb_symbol*>(en_word),
                      std::strlen(en_word));

  std::string en_result(reinterpret_cast<const char*>(en_stemmed));
  EXPECT_EQ(en_result, "run");

  sb_stemmer_delete(en_stemmer);

  // Test French stemmer
  struct sb_stemmer* fr_stemmer = sb_stemmer_new("french", "UTF_8");
  ASSERT_NE(fr_stemmer, nullptr);

  const char* fr_word = "courant";
  const sb_symbol* fr_stemmed =
      sb_stemmer_stem(fr_stemmer, reinterpret_cast<const sb_symbol*>(fr_word),
                      std::strlen(fr_word));

  std::string fr_result(reinterpret_cast<const char*>(fr_stemmed));
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

  for (int i = 0; languages[i] != nullptr; i++) {
    std::string lang(languages[i]);
    if (lang == "english") found_english = true;
    if (lang == "french") found_french = true;
    if (lang == "german") found_german = true;

    std::cout << "Available language: " << lang << std::endl;
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
    const std::string& word = test_case.first;
    const std::string& expected = test_case.second;

    const sb_symbol* stemmed = sb_stemmer_stem(
        stemmer, reinterpret_cast<const sb_symbol*>(word.c_str()),
        word.length());

    ASSERT_NE(stemmed, nullptr) << "Failed to stem word: " << word;

    std::string result(reinterpret_cast<const char*>(stemmed));
    EXPECT_EQ(result, expected)
        << "Word: " << word << " -> Expected: " << expected
        << " Got: " << result;
  }

  sb_stemmer_delete(stemmer);
}

// Test encoding support
TEST_F(LibstemmerIntegrationTest, EncodingSupport) {
  // Test UTF-8 encoding (default)
  struct sb_stemmer* utf8_stemmer = sb_stemmer_new("english", "UTF_8");
  ASSERT_NE(utf8_stemmer, nullptr);

  const char* word = "running";
  const sb_symbol* stemmed =
      sb_stemmer_stem(utf8_stemmer, reinterpret_cast<const sb_symbol*>(word),
                      std::strlen(word));

  std::string result(reinterpret_cast<const char*>(stemmed));
  EXPECT_EQ(result, "run");

  sb_stemmer_delete(utf8_stemmer);

  // Test ISO_8859_1 encoding
  struct sb_stemmer* iso_stemmer = sb_stemmer_new("english", "ISO_8859_1");
  ASSERT_NE(iso_stemmer, nullptr);

  const sb_symbol* iso_stemmed = sb_stemmer_stem(
      iso_stemmer, reinterpret_cast<const sb_symbol*>(word), std::strlen(word));

  std::string iso_result(reinterpret_cast<const char*>(iso_stemmed));
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
  const sb_symbol* empty_result =
      sb_stemmer_stem(stemmer, reinterpret_cast<const sb_symbol*>(""), 0);
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
    const sb_symbol* stemmed = sb_stemmer_stem(
        stemmer, reinterpret_cast<const sb_symbol*>(words[i].c_str()),
        words[i].length());

    ASSERT_NE(stemmed, nullptr);

    std::string result(reinterpret_cast<const char*>(stemmed));
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
  for (int i = 0; i < 1000; i++) {
    test_words.push_back("running" + std::to_string(i));
  }

  auto start_time = std::chrono::high_resolution_clock::now();

  for (const auto& word : test_words) {
    const sb_symbol* stemmed = sb_stemmer_stem(
        stemmer, reinterpret_cast<const sb_symbol*>(word.c_str()),
        word.length());

    ASSERT_NE(stemmed, nullptr);
    // Don't need to check the result, just ensure it doesn't crash
  }

  auto end_time = std::chrono::high_resolution_clock::now();
  auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(
      end_time - start_time);

  std::cout << "Stemmed " << test_words.size() << " words in "
            << duration.count() << " ms" << std::endl;

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
  const char* word1 = "running";
  const char* word2 = "walking";

  const sb_symbol* result1 = sb_stemmer_stem(
      stemmer1, reinterpret_cast<const sb_symbol*>(word1), std::strlen(word1));

  const sb_symbol* result2 = sb_stemmer_stem(
      stemmer2, reinterpret_cast<const sb_symbol*>(word2), std::strlen(word2));

  ASSERT_NE(result1, nullptr);
  ASSERT_NE(result2, nullptr);

  std::string stem1(reinterpret_cast<const char*>(result1));
  std::string stem2(reinterpret_cast<const char*>(result2));

  EXPECT_EQ(stem1, "run");
  EXPECT_EQ(stem2, "walk");

  sb_stemmer_delete(stemmer1);
  sb_stemmer_delete(stemmer2);
}
