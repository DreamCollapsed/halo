#include <gtest/gtest.h>
#include <utf8proc.h>

#include <cstdlib>
#include <cstring>
#include <memory>
#include <string>
#include <vector>

// Helper to normalize a UTF-8 string to NFC form
static std::string NormalizeNFC(const std::string& input) {
  std::string out;
  // Create a vector to hold the data to avoid reinterpret_cast on input
  std::vector<utf8proc_uint8_t> input_data(input.begin(), input.end());
  input_data.push_back(0);  // Null-terminate

  utf8proc_uint8_t* result = nullptr;
  // Use utf8proc_map directly to get the length of the result
  ssize_t len =
      utf8proc_map(input_data.data(), 0, &result,
                   static_cast<utf8proc_option_t>(
                       UTF8PROC_NULLTERM | UTF8PROC_STABLE | UTF8PROC_COMPOSE));

  if (len >= 0 && result != nullptr) {
    // Use a unique_ptr with a custom deleter to handle free() automatically
    std::unique_ptr<utf8proc_uint8_t, decltype(&std::free)> result_ptr(
        result, std::free);

    out.resize(len);
    std::memcpy(out.data(), result, len);
  }
  return out;
}

TEST(Utf8ProcIntegrationTest, BasicCodepointDecode) {
  std::string snow = "\xE2\x9D\x84";  // U+2744 ❄
  utf8proc_int32_t codepoint = 0;
  std::vector<utf8proc_uint8_t> data(snow.begin(), snow.end());

  ssize_t len = utf8proc_iterate(
      data.data(), static_cast<utf8proc_ssize_t>(snow.size()), &codepoint);
  ASSERT_EQ(len, 3);
  EXPECT_EQ(codepoint, 0x2744);
}

TEST(Utf8ProcIntegrationTest, GraphemeClusterIterate) {
  // String with flag (regional indicators) + family emoji (ZWJ sequence)
  std::string text = "🇨🇳👨‍👩‍👧";
  std::vector<std::string> clusters;
  int state = 0;  // state for grapheme break algorithm
  utf8proc_int32_t prev_codepoint = 0;
  bool have_prev = false;
  size_t cluster_start = 0;

  // Convert to vector for safe access
  std::vector<utf8proc_uint8_t> data(text.begin(), text.end());

  for (size_t i = 0; i < text.size();) {
    utf8proc_int32_t codepoint = 0;
    ssize_t len = utf8proc_iterate(
        &data[i], static_cast<utf8proc_ssize_t>(text.size() - i), &codepoint);
    ASSERT_GT(len, 0);
    bool brk = false;
    if (have_prev) {
      brk = utf8proc_grapheme_break_stateful(prev_codepoint, codepoint, &state);
    }
    if (brk) {
      clusters.emplace_back(text.substr(cluster_start, i - cluster_start));
      cluster_start = i;
    }
    prev_codepoint = codepoint;
    have_prev = true;
    i += len;
  }
  clusters.emplace_back(text.substr(cluster_start));
  ASSERT_GE(clusters.size(), 2U);  // Expect at least two clusters
}

TEST(Utf8ProcIntegrationTest, NormalizationNFC) {
  // e + combining acute accent should normalize to precomposed \u00E9
  std::string decomposed = "e\xCC\x81";  // e + COMBINING ACUTE
  std::string normalized = NormalizeNFC(decomposed);
  ASSERT_EQ(normalized.size(), 2);  // UTF-8 for é is 0xC3 0xA9
  EXPECT_EQ(normalized, "\xC3\xA9");
}

TEST(Utf8ProcIntegrationTest, CaseFold) {
  std::string german = "Straße";  // sharp s -> ss when casefolded
  utf8proc_uint8_t* folded_raw = nullptr;

  std::vector<utf8proc_uint8_t> data(german.begin(), german.end());
  data.push_back(0);  // Null-terminate

  ssize_t result_code =
      utf8proc_map(data.data(), static_cast<utf8proc_ssize_t>(german.size()),
                   &folded_raw, UTF8PROC_CASEFOLD);
  ASSERT_GE(result_code, 0);
  ASSERT_NE(folded_raw, nullptr);

  // Use unique_ptr for RAII
  std::unique_ptr<utf8proc_uint8_t, decltype(&std::free)> folded_ptr(folded_raw,
                                                                     std::free);

  std::string out;
  out.resize(result_code);
  std::memcpy(out.data(), folded_raw, result_code);

  EXPECT_EQ(out, "strasse");
}

TEST(Utf8ProcIntegrationTest, InvalidSequence) {
  // Invalid continuation byte sequence
  std::string invalid = "\xE2\x28\xA1";  // bad second byte
  utf8proc_int32_t codepoint = 0;
  std::vector<utf8proc_uint8_t> data(invalid.begin(), invalid.end());

  ssize_t len = utf8proc_iterate(
      data.data(), static_cast<utf8proc_ssize_t>(invalid.size()), &codepoint);
  EXPECT_LT(len, 0);  // error
}

TEST(Utf8ProcIntegrationTest, VersionCheck) {
  EXPECT_EQ(std::string(utf8proc_version()), "2.11.1");
}
