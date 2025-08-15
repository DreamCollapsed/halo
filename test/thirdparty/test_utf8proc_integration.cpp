#include <gtest/gtest.h>
#include <utf8proc.h>

#include <cstdlib>
#include <string>
#include <vector>

// Helper to normalize a UTF-8 string to NFC form
static std::string NormalizeNFC(const std::string& input) {
  std::string out;
  utf8proc_uint8_t* result =
      utf8proc_NFC(reinterpret_cast<const utf8proc_uint8_t*>(input.c_str()));
  if (result) {
    out.assign(reinterpret_cast<char*>(result));
    std::free(result);  // utf8proc allocates with malloc
  }
  return out;
}

TEST(Utf8ProcIntegrationTest, BasicCodepointDecode) {
  const std::string snow = "\xE2\x9D\x84";  // U+2744 ❄
  utf8proc_int32_t cp = 0;
  ssize_t len =
      utf8proc_iterate(reinterpret_cast<const utf8proc_uint8_t*>(snow.c_str()),
                       snow.size(), &cp);
  ASSERT_EQ(len, 3);
  EXPECT_EQ(cp, 0x2744);
}

TEST(Utf8ProcIntegrationTest, GraphemeClusterIterate) {
  // String with flag (regional indicators) + family emoji (ZWJ sequence)
  const std::string text = "🇨🇳👨‍👩‍👧";
  std::vector<std::string> clusters;
  int state = 0;  // state for grapheme break algorithm
  utf8proc_int32_t prev_cp = 0;
  bool have_prev = false;
  size_t cluster_start = 0;
  for (size_t i = 0; i < text.size();) {
    utf8proc_int32_t cp;
    ssize_t len = utf8proc_iterate(
        reinterpret_cast<const utf8proc_uint8_t*>(text.c_str()) + i,
        text.size() - i, &cp);
    ASSERT_GT(len, 0);
    bool brk = false;
    if (have_prev) {
      brk = utf8proc_grapheme_break_stateful(prev_cp, cp, &state);
    }
    if (brk) {
      clusters.emplace_back(text.substr(cluster_start, i - cluster_start));
      cluster_start = i;
    }
    prev_cp = cp;
    have_prev = true;
    i += len;
  }
  clusters.emplace_back(text.substr(cluster_start));
  ASSERT_GE(clusters.size(), 2u);  // Expect at least two clusters
}

TEST(Utf8ProcIntegrationTest, NormalizationNFC) {
  // e + combining acute accent should normalize to precomposed \u00E9
  std::string decomposed = "e\xCC\x81";  // e + COMBINING ACUTE
  std::string normalized = NormalizeNFC(decomposed);
  ASSERT_EQ(normalized.size(), 2u);  // UTF-8 for é is 0xC3 0xA9
  EXPECT_EQ(normalized, "\xC3\xA9");
}

TEST(Utf8ProcIntegrationTest, CaseFold) {
  const std::string german = "Straße";  // sharp s -> ss when casefolded
  utf8proc_uint8_t* folded_raw = nullptr;
  ssize_t rc =
      utf8proc_map(reinterpret_cast<const utf8proc_uint8_t*>(german.c_str()),
                   german.size(), &folded_raw, UTF8PROC_CASEFOLD);
  ASSERT_GE(rc, 0);
  ASSERT_NE(folded_raw, nullptr);
  std::string out(reinterpret_cast<char*>(folded_raw));
  std::free(folded_raw);
  EXPECT_EQ(out, "strasse");
}

TEST(Utf8ProcIntegrationTest, InvalidSequence) {
  // Invalid continuation byte sequence
  std::string invalid = "\xE2\x28\xA1";  // bad second byte
  utf8proc_int32_t cp = 0;
  ssize_t len = utf8proc_iterate(
      reinterpret_cast<const utf8proc_uint8_t*>(invalid.c_str()),
      invalid.size(), &cp);
  EXPECT_LT(len, 0);  // error
}
