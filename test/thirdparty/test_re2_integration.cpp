#include <gtest/gtest.h>
#include <re2/re2.h>

#include <string>
#include <vector>

// Basic integration tests for re2 library

TEST(Re2IntegrationTest, SimpleMatch) {
  RE2 regex("h(.*)o");
  std::string input = "hello";
  std::string inner;
  bool is_match = RE2::FullMatch(input, regex, &inner);
  EXPECT_TRUE(is_match);
  EXPECT_EQ(inner, "ell");
}

TEST(Re2IntegrationTest, NumericExtraction) {
  RE2 regex(R"((-?\d+)\s+(\d+))");
  int first_num = 0;
  int second_num = 0;
  std::string input = "-42 123";
  bool is_match = RE2::FullMatch(input, regex, &first_num, &second_num);
  EXPECT_TRUE(is_match);
  EXPECT_EQ(first_num, -42);
  EXPECT_EQ(second_num, 123);
}

TEST(Re2IntegrationTest, PartialMatch) {
  std::string text = "The quick brown fox jumps over 15 lazy dogs";
  int number = 0;
  bool is_match = RE2::PartialMatch(text, RE2(R"((\d+) lazy)"), &number);
  EXPECT_TRUE(is_match);
  EXPECT_EQ(number, 15);
}

TEST(Re2IntegrationTest, Replace) {
  std::string text = "color colour colr";
  int count = RE2::GlobalReplace(&text, "colou?r", "paint");
  EXPECT_EQ(count, 2);
  EXPECT_EQ(text, "paint paint colr");
}

TEST(Re2IntegrationTest, UTF8Match) {
  // Match a single UTF-8 Chinese character followed by digits
  std::string text = "汉123";
  RE2 regex(R"(^.\d+)");
  EXPECT_TRUE(RE2::FullMatch(text, regex));
}

TEST(Re2IntegrationTest, NoMatch) {
  RE2 regex("abc");
  std::string text = "abx";
  EXPECT_FALSE(RE2::FullMatch(text, regex));
}

TEST(Re2IntegrationTest, CapturingGroups) {
  RE2 regex(R"((\w+)-(\w+)-(\d+))");
  std::string first;
  std::string second;
  int number = 0;
  std::string input = "alpha-beta-999";
  bool is_match = RE2::FullMatch(input, regex, &first, &second, &number);
  EXPECT_TRUE(is_match);
  EXPECT_EQ(first, "alpha");
  EXPECT_EQ(second, "beta");
  EXPECT_EQ(number, 999);
}

TEST(Re2IntegrationTest, ValidateEmail) {
  RE2 regex(R"(^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$)");
  EXPECT_TRUE(RE2::FullMatch("user.name+tag@test-domain.com", regex));
  EXPECT_FALSE(RE2::FullMatch("invalid@@example..com", regex));
}

TEST(Re2IntegrationTest, Iteration) {
  std::string text = "id=123 id=456 id=789";
  RE2 regex(R"(id=(\d+))");
  re2::StringPiece input(text);
  std::vector<int> values;
  int captured = 0;
  // Capture the numeric subgroup directly as int for efficiency and to avoid
  // string_view conversion.
  while (RE2::FindAndConsume(&input, regex, &captured)) {
    values.push_back(captured);
  }
  EXPECT_EQ(values.size(), 3U);
  EXPECT_EQ(values[0], 123);
  EXPECT_EQ(values[1], 456);
  EXPECT_EQ(values[2], 789);
}
