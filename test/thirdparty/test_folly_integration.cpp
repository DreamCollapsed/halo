#include <folly/FBString.h>
#include <gtest/gtest.h>

TEST(FollyIntegration, FBStringBasic) {
  folly::fbstring str = "Hello";
  str += " Folly!";
  EXPECT_EQ(str, "Hello Folly!");
}

TEST(FollyIntegration, FBStringReserve) {
  folly::fbstring str;
  str.reserve(100);
  EXPECT_GE(str.capacity(), 100);
}

int main(int argc, char** argv) {
  testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}