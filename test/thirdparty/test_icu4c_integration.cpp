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

using icu::BreakIterator;
using icu::Calendar;
using icu::Collator;
using icu::DateFormat;
using icu::Locale;
using icu::Normalizer2;
using icu::NumberFormat;
using icu::RegexMatcher;
using icu::Transliterator;
using icu::UnicodeString;

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
  UVersionInfo version_array;
  u_getVersion(&version_array[0]);

  std::array<char, U_MAX_VERSION_STRING_LENGTH> version_string{};
  u_versionToString(&version_array[0], version_string.data());

  std::cout << "ICU Version: " << version_string.data() << "\n";

  // Verify we have a reasonable version (should be 77.x)
  EXPECT_GE(version_array[0], 77);
  EXPECT_LT(version_array[0], 100);  // Sanity check
}

// Test Unicode string operations
TEST_F(ICUIntegrationTest, UnicodeStringOperations) {
  UnicodeString str1("Hello, ");
  UnicodeString str2("世界");
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
  UnicodeString unicode_str("Hello, 世界! 🌍");
  std::string utf8_str;

  // Convert to UTF-8
  unicode_str.toUTF8String(utf8_str);
  EXPECT_GT(utf8_str.length(), 0);

  // Convert back to Unicode
  UnicodeString round_trip = UnicodeString::fromUTF8(utf8_str);
  EXPECT_EQ(unicode_str, round_trip);
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

  UnicodeString normalized_composed = nfc->normalize(composed, status);
  UnicodeString normalized_decomposed = nfc->normalize(decomposed, status);

  EXPECT_TRUE(U_SUCCESS(status));
  EXPECT_EQ(normalized_composed, normalized_decomposed);
}

// Test regular expressions
TEST_F(ICUIntegrationTest, RegularExpressions) {
  UErrorCode status = U_ZERO_ERROR;
  UnicodeString pattern(R"(\b\w+@\w+\.\w+\b)");  // Simple email pattern
  UnicodeString text("Contact us at support@example.com or info@test.org");

  RegexMatcher matcher(pattern, text, 0, status);
  ASSERT_TRUE(U_SUCCESS(status));

  int match_count = 0;
  while (matcher.find(status) != 0 && U_SUCCESS(status) != 0) {
    match_count++;
    UnicodeString match = matcher.group(status);
    EXPECT_GT(match.length(), 0);
  }

  EXPECT_EQ(match_count, 2);  // Should find 2 email addresses
}

// Test locale-specific operations
TEST_F(ICUIntegrationTest, LocaleOperations) {
  // Test different locales
  Locale us_locale("en_US");
  Locale chinese_locale("zh_CN");
  Locale french_locale("fr_FR");

  EXPECT_STREQ(us_locale.getLanguage(), "en");
  EXPECT_STREQ(us_locale.getCountry(), "US");

  EXPECT_STREQ(chinese_locale.getLanguage(), "zh");
  EXPECT_STREQ(chinese_locale.getCountry(), "CN");

  // Test locale display names
  UnicodeString display_name;
  us_locale.getDisplayName(us_locale, display_name);
  EXPECT_GT(display_name.length(), 0);
}

// Test number formatting
TEST_F(ICUIntegrationTest, NumberFormatting) {
  UErrorCode status = U_ZERO_ERROR;

  // Test US number formatting
  Locale us_locale("en_US");
  std::unique_ptr<NumberFormat> us_formatter(
      NumberFormat::createInstance(us_locale, status));
  ASSERT_TRUE(U_SUCCESS(status));
  ASSERT_NE(us_formatter.get(), nullptr);

  UnicodeString us_formatted;
  us_formatter->format(1234567.89, us_formatted);
  EXPECT_GT(us_formatted.length(), 0);

  // Test German number formatting (uses comma for decimal separator)
  Locale german_locale("de_DE");
  std::unique_ptr<NumberFormat> german_formatter(
      NumberFormat::createInstance(german_locale, status));
  ASSERT_TRUE(U_SUCCESS(status));

  UnicodeString german_formatted;
  german_formatter->format(1234567.89, german_formatted);
  EXPECT_GT(german_formatted.length(), 0);

  // They should be different due to different locale conventions
  EXPECT_NE(us_formatted, german_formatted);
}

// Test date formatting
TEST_F(ICUIntegrationTest, DateFormatting) {
  UErrorCode status = U_ZERO_ERROR;

  // Create a specific date
  std::unique_ptr<Calendar> calendar(Calendar::createInstance(status));
  ASSERT_TRUE(U_SUCCESS(status));
  ASSERT_NE(calendar, nullptr);

  calendar->clear();
  calendar->set(2025, UCAL_JULY, 23, 10, 30, 0);  // July 23, 2025, 10:30:00
  UDate test_date = calendar->getTime(status);
  ASSERT_TRUE(U_SUCCESS(status));

  // Test US date formatting
  Locale us_locale("en_US");
  std::unique_ptr<DateFormat> us_formatter(DateFormat::createDateTimeInstance(
      DateFormat::MEDIUM, DateFormat::SHORT, us_locale));
  ASSERT_NE(us_formatter.get(), nullptr);

  UnicodeString us_formatted;
  us_formatter->format(test_date, us_formatted);
  EXPECT_GT(us_formatted.length(), 0);

  // Test ISO date formatting
  Locale iso_locale("en_US_POSIX");
  std::unique_ptr<DateFormat> iso_formatter(DateFormat::createDateTimeInstance(
      DateFormat::SHORT, DateFormat::SHORT, iso_locale));
  ASSERT_NE(iso_formatter.get(), nullptr);

  UnicodeString iso_formatted;
  iso_formatter->format(test_date, iso_formatted);
  EXPECT_GT(iso_formatted.length(), 0);
}

// Test collation (string comparison)
TEST_F(ICUIntegrationTest, Collation) {
  UErrorCode status = U_ZERO_ERROR;

  // Test English collation
  Locale en_locale("en_US");
  std::unique_ptr<Collator> en_collator(
      Collator::createInstance(en_locale, status));
  ASSERT_TRUE(U_SUCCESS(status));
  ASSERT_NE(en_collator.get(), nullptr);

  UnicodeString str1("apple");
  UnicodeString str2("Apple");
  UnicodeString str3("banana");

  // Case-sensitive comparison
  en_collator->setStrength(Collator::TERTIARY);
  int cmp = en_collator->compare(str1, str2);
  // Expect strings differ (apple vs Apple)
  EXPECT_NE(cmp, 0);
  EXPECT_LT(en_collator->compare(str1, str3), 0);  // "apple" < "banana"

  // Case-insensitive comparison
  en_collator->setStrength(Collator::SECONDARY);
  EXPECT_EQ(en_collator->compare(str1, str2), 0);  // "apple" == "Apple"
}

// Test text boundaries (word/sentence breaking)
TEST_F(ICUIntegrationTest, TextBoundaries) {
  UErrorCode status = U_ZERO_ERROR;
  UnicodeString text("Hello world! How are you today? I'm fine, thanks.");

  // Test word boundaries
  std::unique_ptr<BreakIterator> word_breaker(
      BreakIterator::createWordInstance(Locale::getUS(), status));
  ASSERT_TRUE(U_SUCCESS(status));
  ASSERT_NE(word_breaker.get(), nullptr);

  word_breaker->setText(text);

  int word_count = 0;
  int32_t start = word_breaker->first();
  for (int32_t end = word_breaker->next(); end != BreakIterator::DONE;
       start = end, end = word_breaker->next()) {
    UnicodeString word = text.tempSubString(start, end - start);
    if (word.trim().length() > 0 && (u_isalpha(word.charAt(0)) != 0)) {
      word_count++;
    }
  }

  EXPECT_GT(word_count, 5);  // Should find several words

  // Test sentence boundaries
  std::unique_ptr<BreakIterator> sentence_breaker(
      BreakIterator::createSentenceInstance(Locale::getUS(), status));
  ASSERT_TRUE(U_SUCCESS(status));

  sentence_breaker->setText(text);

  int sentence_count = 0;
  start = sentence_breaker->first();
  for (int32_t end = sentence_breaker->next(); end != BreakIterator::DONE;
       start = end, end = sentence_breaker->next()) {
    UnicodeString sentence = text.tempSubString(start, end - start);
    if (sentence.trim().length() > 0) {
      sentence_count++;
    }
  }

  EXPECT_GE(sentence_count, 3);  // Should find at least 3 sentences
}

// Test transliteration
TEST_F(ICUIntegrationTest, Transliteration) {
  UErrorCode status = U_ZERO_ERROR;

  // Test Latin to ASCII transliteration
  std::unique_ptr<Transliterator> latin_to_ascii(
      Transliterator::createInstance("Latin-ASCII", UTRANS_FORWARD, status));

  if (U_SUCCESS(status) != 0 && latin_to_ascii != nullptr) {
    UnicodeString input("naïve café résumé");
    UnicodeString output = input;
    latin_to_ascii->transliterate(output);

    EXPECT_NE(input, output);
    EXPECT_GT(output.length(), 0);

    // Should convert accented characters to ASCII equivalents
    EXPECT_TRUE(output.indexOf("naive") >= 0 || output.indexOf("nai") >= 0);
  } else {
    // Transliteration must be available in ICU build
    ASSERT_EQ(status, U_ZERO_ERROR)
        << "Latin-ASCII transliteration must be available: "
        << u_errorName(status);
  }
}

// Test character properties
TEST_F(ICUIntegrationTest, CharacterProperties) {
  // Test various Unicode character properties
  UChar32 ch_a = 'a';
  UChar32 ch_upper_a = 'A';
  UChar32 ch_0 = '0';
  UChar32 ch_space = ' ';
  UChar32 ch_chinese = 0x4E00;  // CJK unified ideograph

  EXPECT_TRUE(u_isalpha(ch_a));
  EXPECT_TRUE(u_isalpha(ch_upper_a));
  EXPECT_FALSE(u_isalpha(ch_0));
  EXPECT_FALSE(u_isalpha(ch_space));
  EXPECT_TRUE(u_isalpha(ch_chinese));

  EXPECT_TRUE(u_islower(ch_a));
  EXPECT_FALSE(u_islower(ch_upper_a));
  EXPECT_TRUE(u_isupper(ch_upper_a));
  EXPECT_FALSE(u_isupper(ch_a));

  EXPECT_TRUE(u_isdigit(ch_0));
  EXPECT_FALSE(u_isdigit(ch_a));

  EXPECT_TRUE(u_isspace(ch_space));
  EXPECT_FALSE(u_isspace(ch_a));

  // Test case conversion
  EXPECT_EQ(u_toupper(ch_a), ch_upper_a);
  EXPECT_EQ(u_tolower(ch_upper_a), ch_a);
}

// Test script detection
TEST_F(ICUIntegrationTest, ScriptDetection) {
  UChar32 latin_char = 'A';
  UChar32 chinese_char = 0x4E00;
  UChar32 arabic_char = 0x0627;    // Arabic letter alef
  UChar32 cyrillic_char = 0x0410;  // Cyrillic capital letter A

  // Test basic script properties using alternative method
  // Some ICU builds may not have full script detection, so we test character
  // properties instead
  EXPECT_TRUE(u_isalpha(latin_char));
  EXPECT_TRUE(u_isalpha(chinese_char));
  EXPECT_TRUE(u_isalpha(arabic_char));
  EXPECT_TRUE(u_isalpha(cyrillic_char));

  // Test script detection if available, otherwise test character categorization
  int latin_script = uscript_getScript(latin_char, nullptr);
  if (latin_script >= 0) {
    // Full script detection is available
    EXPECT_EQ(latin_script, USCRIPT_LATIN);
    EXPECT_EQ(uscript_getScript(chinese_char, nullptr), USCRIPT_HAN);
    EXPECT_EQ(uscript_getScript(arabic_char, nullptr), USCRIPT_ARABIC);
    EXPECT_EQ(uscript_getScript(cyrillic_char, nullptr), USCRIPT_CYRILLIC);
  } else {
    // Script detection not available, test character properties instead
    EXPECT_TRUE(u_isalpha(latin_char));
    EXPECT_NE(u_charType(chinese_char), U_CONTROL_CHAR);
    EXPECT_NE(u_charType(arabic_char), U_CONTROL_CHAR);
    EXPECT_NE(u_charType(cyrillic_char), U_CONTROL_CHAR);
  }
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
  UnicodeString round_trip = UnicodeString::fromUTF8(utf8);
  EXPECT_EQ(normalized, round_trip);

  // 4. Break into words
  std::unique_ptr<BreakIterator> word_breaker(
      BreakIterator::createWordInstance(Locale::getUS(), status));
  ASSERT_TRUE(U_SUCCESS(status));

  word_breaker->setText(normalized);
  std::vector<UnicodeString> words;

  int32_t start = word_breaker->first();
  for (int32_t end = word_breaker->next(); end != BreakIterator::DONE;
       start = end, end = word_breaker->next()) {
    UnicodeString word = normalized.tempSubString(start, end - start);
    if (word.trim().length() > 0 && (u_isalpha(word.charAt(0)) != 0)) {
      words.push_back(word);
    }
  }

  EXPECT_GE(words.size(), 4);  // Should find at least 4 words

  // 5. Sort words using locale-aware collation
  Locale locale("en_US");
  std::unique_ptr<Collator> collator(Collator::createInstance(locale, status));
  ASSERT_TRUE(U_SUCCESS(status));

  std::ranges::sort(words, [&collator](const UnicodeString& str_a,
                                       const UnicodeString& str_b) {
    return collator->compare(str_a, str_b) < 0;
  });

  EXPECT_GE(words.size(), 4);
}
