#include <gtest/gtest.h>
#include <re2/re2.h>

#include <string>
#include <vector>

// Basic integration tests for re2 library

TEST(Re2IntegrationTest, SimpleMatch) {
  RE2 re("h(.*)o");
  std::string input = "hello";
  std::string inner;
  bool ok = RE2::FullMatch(input, re, &inner);
  EXPECT_TRUE(ok);
  EXPECT_EQ(inner, "ell");
}

TEST(Re2IntegrationTest, NumericExtraction) {
  RE2 re("(-?\\d+)\\s+(\\d+)");
  int a = 0, b = 0;
  std::string input = "-42 123";
  bool ok = RE2::FullMatch(input, re, &a, &b);
  EXPECT_TRUE(ok);
  EXPECT_EQ(a, -42);
  EXPECT_EQ(b, 123);
}

TEST(Re2IntegrationTest, PartialMatch) {
  std::string text = "The quick brown fox jumps over 15 lazy dogs";
  int number = 0;
  bool ok = RE2::PartialMatch(text, RE2("(\\d+) lazy"), &number);
  EXPECT_TRUE(ok);
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
  RE2 re("^.\\d+");
  EXPECT_TRUE(RE2::FullMatch(text, re));
}

TEST(Re2IntegrationTest, NoMatch) {
  RE2 re("abc");
  std::string text = "abx";
  EXPECT_FALSE(RE2::FullMatch(text, re));
}

TEST(Re2IntegrationTest, CapturingGroups) {
  RE2 re("(\\w+)-(\\w+)-(\\d+)");
  std::string first, second;
  int number = 0;
  std::string input = "alpha-beta-999";
  bool ok = RE2::FullMatch(input, re, &first, &second, &number);
  EXPECT_TRUE(ok);
  EXPECT_EQ(first, "alpha");
  EXPECT_EQ(second, "beta");
  EXPECT_EQ(number, 999);
}

TEST(Re2IntegrationTest, ValidateEmail) {
  RE2 re("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$");
  EXPECT_TRUE(RE2::FullMatch("user.name+tag@test-domain.com", re));
  EXPECT_FALSE(RE2::FullMatch("invalid@@example..com", re));
}

TEST(Re2IntegrationTest, Iteration) {
  std::string text = "id=123 id=456 id=789";
  RE2 re("id=(\\d+)");
  re2::StringPiece input(text);
  std::vector<int> values;
  int captured = 0;
  // Capture the numeric subgroup directly as int for efficiency and to avoid
  // string_view conversion.
  while (RE2::FindAndConsume(&input, re, &captured)) {
    values.push_back(captured);
  }
  EXPECT_EQ(values.size(), 3u);
  EXPECT_EQ(values[0], 123);
  EXPECT_EQ(values[1], 456);
  EXPECT_EQ(values[2], 789);
}
