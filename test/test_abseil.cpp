#include <gtest/gtest.h>
#include "absl/strings/str_cat.h"
#include "absl/strings/str_split.h"

TEST(AbseilTest, StrCatWorks) {
    std::string result = absl::StrCat("hello", " ", "world", "!", 123);
    EXPECT_EQ(result, "hello world!123");
}

TEST(AbseilTest, StrSplitWorks) {
    std::vector<std::string> parts = absl::StrSplit("a,b,c", ',');
    ASSERT_EQ(parts.size(), 3);
    EXPECT_EQ(parts[0], "a");
    EXPECT_EQ(parts[1], "b");
    EXPECT_EQ(parts[2], "c");
}

int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
