#include <gtest/gtest.h>

TEST(SampleTest, Addition) {
    EXPECT_EQ(1 + 1, 2);
}

TEST(SampleTest, StringCompare) {
    std::string a = "hello";
    std::string b = "hello";
    EXPECT_EQ(a, b);
}
