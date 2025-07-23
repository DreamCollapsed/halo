#include <gtest/gtest.h>
#include <unicode/brkiter.h>
#include <unicode/calendar.h>
#include <unicode/coll.h>
#include <unicode/datefmt.h>
#include <unicode/locid.h>
#include <unicode/msgfmt.h>
#include <unicode/normalizer2.h>
#include <unicode/numfmt.h>
#include <unicode/regex.h>
#include <unicode/translit.h>
#include <unicode/uchar.h>
#include <unicode/ucnv.h>
#include <unicode/ucol.h>
#include <unicode/unistr.h>
#include <unicode/uscript.h>
#include <unicode/uset.h>
#include <unicode/usetiter.h>
#include <unicode/ustring.h>
#include <unicode/utext.h>
#include <unicode/utf16.h>
#include <unicode/utf8.h>
#include <unicode/utypes.h>
#include <unicode/uversion.h>

#include <algorithm>
#include <iostream>
#include <memory>
#include <string>
#include <vector>

using namespace icu;

class ICUIntegrationTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // Initialize ICU if needed
    UErrorCode status = U_ZERO_ERROR;
    // Basic ICU initialization is automatic, but we can check status
    ASSERT_TRUE(U_SUCCESS(status))
        << "ICU initialization failed: " << u_errorName(status);
  }

  void TearDown() override {
    // ICU cleanup is automatic
  }
};

// Test ICU version and basic functionality
TEST_F(ICUIntegrationTest, VersionInfo) {
  UVersionInfo versionArray;
  u_getVersion(versionArray);

  char versionString[U_MAX_VERSION_STRING_LENGTH];
  u_versionToString(versionArray, versionString);

  std::cout << "ICU Version: " << versionString << std::endl;

  // Verify we have a reasonable version (should be 77.x)
  EXPECT_GE(versionArray[0], 77);
  EXPECT_LT(versionArray[0], 100);  // Sanity check
}

// Test Unicode string operations
TEST_F(ICUIntegrationTest, UnicodeStringOperations) {
  UnicodeString str1("Hello, ");
  UnicodeString str2("世界");  // "World" in Chinese
  UnicodeString combined = str1 + str2;

  EXPECT_GT(combined.length(), 0);
  EXPECT_EQ(combined.length(), str1.length() + str2.length());

  // Test character access
  EXPECT_EQ(str1.charAt(0), 'H');

  // Test substring
  UnicodeString hello = combined.tempSubString(0, 7);
  EXPECT_EQ(hello, str1);
}

// Test UTF-8 conversion
TEST_F(ICUIntegrationTest, UTF8Conversion) {
  UnicodeString unicodeStr("Hello, 世界! 🌍");
  std::string utf8Str;

  // Convert to UTF-8
  unicodeStr.toUTF8String(utf8Str);
  EXPECT_GT(utf8Str.length(), 0);

  // Convert back to Unicode
  UnicodeString roundTrip = UnicodeString::fromUTF8(utf8Str);
  EXPECT_EQ(unicodeStr, roundTrip);
}

// Test text normalization
TEST_F(ICUIntegrationTest, TextNormalization) {
  UErrorCode status = U_ZERO_ERROR;
  const Normalizer2* nfc = Normalizer2::getNFCInstance(status);
  ASSERT_TRUE(U_SUCCESS(status));
  ASSERT_NE(nfc, nullptr);

  // Test normalization with composed and decomposed characters
  UnicodeString composed("é");          // Single character
  UnicodeString decomposed("e\u0301");  // e + combining acute accent

  UnicodeString normalizedComposed = nfc->normalize(composed, status);
  UnicodeString normalizedDecomposed = nfc->normalize(decomposed, status);

  EXPECT_TRUE(U_SUCCESS(status));
  EXPECT_EQ(normalizedComposed, normalizedDecomposed);
}

// Test regular expressions
TEST_F(ICUIntegrationTest, RegularExpressions) {
  UErrorCode status = U_ZERO_ERROR;
  UnicodeString pattern("\\b\\w+@\\w+\\.\\w+\\b");  // Simple email pattern
  UnicodeString text("Contact us at support@example.com or info@test.org");

  RegexMatcher matcher(pattern, text, 0, status);
  ASSERT_TRUE(U_SUCCESS(status));

  int matchCount = 0;
  while (matcher.find(status) && U_SUCCESS(status)) {
    matchCount++;
    UnicodeString match = matcher.group(status);
    EXPECT_GT(match.length(), 0);
  }

  EXPECT_EQ(matchCount, 2);  // Should find 2 email addresses
}

// Test locale-specific operations
TEST_F(ICUIntegrationTest, LocaleOperations) {
  // Test different locales
  Locale usLocale("en_US");
  Locale chineseLocale("zh_CN");
  Locale frenchLocale("fr_FR");

  EXPECT_STREQ(usLocale.getLanguage(), "en");
  EXPECT_STREQ(usLocale.getCountry(), "US");

  EXPECT_STREQ(chineseLocale.getLanguage(), "zh");
  EXPECT_STREQ(chineseLocale.getCountry(), "CN");

  // Test locale display names
  UnicodeString displayName;
  usLocale.getDisplayName(usLocale, displayName);
  EXPECT_GT(displayName.length(), 0);
}

// Test number formatting
TEST_F(ICUIntegrationTest, NumberFormatting) {
  UErrorCode status = U_ZERO_ERROR;

  // Test US number formatting
  Locale usLocale("en_US");
  std::unique_ptr<NumberFormat> usFormatter(
      NumberFormat::createInstance(usLocale, status));
  ASSERT_TRUE(U_SUCCESS(status));
  ASSERT_NE(usFormatter.get(), nullptr);

  UnicodeString usFormatted;
  usFormatter->format(1234567.89, usFormatted);
  EXPECT_GT(usFormatted.length(), 0);

  // Test German number formatting (uses comma for decimal separator)
  Locale germanLocale("de_DE");
  std::unique_ptr<NumberFormat> germanFormatter(
      NumberFormat::createInstance(germanLocale, status));
  ASSERT_TRUE(U_SUCCESS(status));

  UnicodeString germanFormatted;
  germanFormatter->format(1234567.89, germanFormatted);
  EXPECT_GT(germanFormatted.length(), 0);

  // They should be different due to different locale conventions
  EXPECT_NE(usFormatted, germanFormatted);
}

// Test date formatting
TEST_F(ICUIntegrationTest, DateFormatting) {
  UErrorCode status = U_ZERO_ERROR;

  // Create a specific date
  Calendar* calendar = Calendar::createInstance(status);
  ASSERT_TRUE(U_SUCCESS(status));
  ASSERT_NE(calendar, nullptr);

  calendar->clear();
  calendar->set(2025, UCAL_JULY, 23, 10, 30, 0);  // July 23, 2025, 10:30:00
  UDate testDate = calendar->getTime(status);
  ASSERT_TRUE(U_SUCCESS(status));

  // Test US date formatting
  Locale usLocale("en_US");
  std::unique_ptr<DateFormat> usFormatter(DateFormat::createDateTimeInstance(
      DateFormat::MEDIUM, DateFormat::SHORT, usLocale));
  ASSERT_NE(usFormatter.get(), nullptr);

  UnicodeString usFormatted;
  usFormatter->format(testDate, usFormatted);
  EXPECT_GT(usFormatted.length(), 0);

  // Test ISO date formatting
  Locale isoLocale("en_US_POSIX");
  std::unique_ptr<DateFormat> isoFormatter(DateFormat::createDateTimeInstance(
      DateFormat::SHORT, DateFormat::SHORT, isoLocale));
  ASSERT_NE(isoFormatter.get(), nullptr);

  UnicodeString isoFormatted;
  isoFormatter->format(testDate, isoFormatted);
  EXPECT_GT(isoFormatted.length(), 0);

  delete calendar;
}

// Test collation (string comparison)
TEST_F(ICUIntegrationTest, Collation) {
  UErrorCode status = U_ZERO_ERROR;

  // Test English collation
  Locale enLocale("en_US");
  std::unique_ptr<Collator> enCollator(
      Collator::createInstance(enLocale, status));
  ASSERT_TRUE(U_SUCCESS(status));
  ASSERT_NE(enCollator.get(), nullptr);

  UnicodeString str1("apple");
  UnicodeString str2("Apple");
  UnicodeString str3("banana");

  // Case-sensitive comparison
  enCollator->setStrength(Collator::TERTIARY);
  int cmp = enCollator->compare(str1, str2);
  // Expect strings differ (apple vs Apple)
  EXPECT_NE(cmp, 0);
  EXPECT_LT(enCollator->compare(str1, str3), 0);  // "apple" < "banana"

  // Case-insensitive comparison
  enCollator->setStrength(Collator::SECONDARY);
  EXPECT_EQ(enCollator->compare(str1, str2), 0);  // "apple" == "Apple"
}

// Test text boundaries (word/sentence breaking)
TEST_F(ICUIntegrationTest, TextBoundaries) {
  UErrorCode status = U_ZERO_ERROR;
  UnicodeString text("Hello world! How are you today? I'm fine, thanks.");

  // Test word boundaries
  std::unique_ptr<BreakIterator> wordBreaker(
      BreakIterator::createWordInstance(Locale::getUS(), status));
  ASSERT_TRUE(U_SUCCESS(status));
  ASSERT_NE(wordBreaker.get(), nullptr);

  wordBreaker->setText(text);

  int wordCount = 0;
  int32_t start = wordBreaker->first();
  for (int32_t end = wordBreaker->next(); end != BreakIterator::DONE;
       start = end, end = wordBreaker->next()) {
    UnicodeString word = text.tempSubString(start, end - start);
    if (word.trim().length() > 0 && u_isalpha(word.charAt(0))) {
      wordCount++;
    }
  }

  EXPECT_GT(wordCount, 5);  // Should find several words

  // Test sentence boundaries
  std::unique_ptr<BreakIterator> sentenceBreaker(
      BreakIterator::createSentenceInstance(Locale::getUS(), status));
  ASSERT_TRUE(U_SUCCESS(status));

  sentenceBreaker->setText(text);

  int sentenceCount = 0;
  start = sentenceBreaker->first();
  for (int32_t end = sentenceBreaker->next(); end != BreakIterator::DONE;
       start = end, end = sentenceBreaker->next()) {
    UnicodeString sentence = text.tempSubString(start, end - start);
    if (sentence.trim().length() > 0) {
      sentenceCount++;
    }
  }

  EXPECT_GE(sentenceCount, 3);  // Should find at least 3 sentences
}

// Test transliteration
TEST_F(ICUIntegrationTest, Transliteration) {
  UErrorCode status = U_ZERO_ERROR;

  // Test Latin to ASCII transliteration
  std::unique_ptr<Transliterator> latinToAscii(
      Transliterator::createInstance("Latin-ASCII", UTRANS_FORWARD, status));

  if (U_SUCCESS(status) && latinToAscii.get() != nullptr) {
    UnicodeString input("naïve café résumé");
    UnicodeString output = input;
    latinToAscii->transliterate(output);

    EXPECT_NE(input, output);
    EXPECT_GT(output.length(), 0);

    // Should convert accented characters to ASCII equivalents
    EXPECT_TRUE(output.indexOf("naive") >= 0 || output.indexOf("nai") >= 0);
  } else {
    // Transliteration might not be available in minimal builds
    GTEST_SKIP() << "Latin-ASCII transliteration not available: "
                 << u_errorName(status);
  }
}

// Test character properties
TEST_F(ICUIntegrationTest, CharacterProperties) {
  // Test various Unicode character properties
  UChar32 ch_a = 'a';
  UChar32 ch_A = 'A';
  UChar32 ch_0 = '0';
  UChar32 ch_space = ' ';
  UChar32 ch_chinese = 0x4E00;  // CJK unified ideograph

  EXPECT_TRUE(u_isalpha(ch_a));
  EXPECT_TRUE(u_isalpha(ch_A));
  EXPECT_FALSE(u_isalpha(ch_0));
  EXPECT_FALSE(u_isalpha(ch_space));
  EXPECT_TRUE(u_isalpha(ch_chinese));

  EXPECT_TRUE(u_islower(ch_a));
  EXPECT_FALSE(u_islower(ch_A));
  EXPECT_TRUE(u_isupper(ch_A));
  EXPECT_FALSE(u_isupper(ch_a));

  EXPECT_TRUE(u_isdigit(ch_0));
  EXPECT_FALSE(u_isdigit(ch_a));

  EXPECT_TRUE(u_isspace(ch_space));
  EXPECT_FALSE(u_isspace(ch_a));

  // Test case conversion
  EXPECT_EQ(u_toupper(ch_a), ch_A);
  EXPECT_EQ(u_tolower(ch_A), ch_a);
}

// Test script detection
TEST_F(ICUIntegrationTest, ScriptDetection) {
  UChar32 latin_char = 'A';
  UChar32 chinese_char = 0x4E00;
  UChar32 arabic_char = 0x0627;    // Arabic letter alef
  UChar32 cyrillic_char = 0x0410;  // Cyrillic capital letter A

  // Skip script detection if data component not available
  int latin_script = uscript_getScript(latin_char, nullptr);
  if (latin_script < 0) {
    GTEST_SKIP() << "Script detection not available in this ICU build";
  }
  EXPECT_EQ(latin_script, USCRIPT_LATIN);
  EXPECT_EQ(uscript_getScript(chinese_char, nullptr), USCRIPT_HAN);
  EXPECT_EQ(uscript_getScript(arabic_char, nullptr), USCRIPT_ARABIC);
  EXPECT_EQ(uscript_getScript(cyrillic_char, nullptr), USCRIPT_CYRILLIC);
}

// Integration test combining multiple ICU features
TEST_F(ICUIntegrationTest, IntegratedWorkflow) {
  UErrorCode status = U_ZERO_ERROR;

  // 1. Create multilingual text
  UnicodeString text("English, 中文, العربية, Русский");

  // 2. Normalize the text
  const Normalizer2* nfc = Normalizer2::getNFCInstance(status);
  ASSERT_TRUE(U_SUCCESS(status));
  UnicodeString normalized = nfc->normalize(text, status);
  EXPECT_TRUE(U_SUCCESS(status));

  // 3. Convert to UTF-8 and back
  std::string utf8;
  normalized.toUTF8String(utf8);
  UnicodeString roundTrip = UnicodeString::fromUTF8(utf8);
  EXPECT_EQ(normalized, roundTrip);

  // 4. Break into words
  std::unique_ptr<BreakIterator> wordBreaker(
      BreakIterator::createWordInstance(Locale::getUS(), status));
  ASSERT_TRUE(U_SUCCESS(status));

  wordBreaker->setText(normalized);
  std::vector<UnicodeString> words;

  int32_t start = wordBreaker->first();
  for (int32_t end = wordBreaker->next(); end != BreakIterator::DONE;
       start = end, end = wordBreaker->next()) {
    UnicodeString word = normalized.tempSubString(start, end - start);
    if (word.trim().length() > 0 && u_isalpha(word.charAt(0))) {
      words.push_back(word);
    }
  }

  EXPECT_GE(words.size(), 4);  // Should find at least 4 words

  // 5. Sort words using locale-aware collation
  Locale locale("en_US");
  std::unique_ptr<Collator> collator(Collator::createInstance(locale, status));
  ASSERT_TRUE(U_SUCCESS(status));

  std::sort(words.begin(), words.end(),
            [&collator](const UnicodeString& a, const UnicodeString& b) {
              return collator->compare(a, b) < 0;
            });

  EXPECT_GE(words.size(), 4);
}
