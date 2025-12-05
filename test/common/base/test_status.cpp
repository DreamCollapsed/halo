#include <gtest/gtest.h>

#include <sstream>

import halo.common;

namespace halo::common::base {

TEST(StatusTest, DefaultConstructor) {
  Status s;
  EXPECT_TRUE(s.ok());
  EXPECT_EQ(s.code(), Status::Code::kOk);
  EXPECT_EQ(s.message(), "OK");
}

TEST(StatusTest, ErrorConstructor) {
  Status s = Status::Error("Something went wrong");
  EXPECT_FALSE(s.ok());
  EXPECT_EQ(s.code(), Status::Code::kError);
  EXPECT_EQ(s.message(), "Something went wrong");
  EXPECT_EQ(s.toString(), "[100-kError]{Something went wrong}");
}

TEST(StatusTest, CopyConstructor) {
  Status s1 = Status::Invalid("Invalid arg");
  Status s2(s1);  // NOLINT(performance-unnecessary-copy-initialization)
  EXPECT_EQ(s2.code(), s1.code());
  EXPECT_EQ(s2.message(), s1.message());
}

TEST(StatusTest, MoveConstructor) {
  Status s1 = Status::Invalid("Invalid arg");
  Status s2(std::move(s1));
  EXPECT_EQ(s2.code(), Status::Code::kInvalid);
  EXPECT_EQ(s2.message(), "Invalid arg");
}

TEST(StatusTest, CopyAssignment) {
  Status s1 = Status::Invalid("Invalid arg");
  Status s2;
  s2 = s1;
  EXPECT_EQ(s2.code(), s1.code());
  EXPECT_EQ(s2.message(), s1.message());
}

TEST(StatusTest, MoveAssignment) {
  Status s1 = Status::Invalid("Invalid arg");
  Status s2;
  s2 = std::move(s1);
  EXPECT_EQ(s2.code(), Status::Code::kInvalid);
  EXPECT_EQ(s2.message(), "Invalid arg");
}

TEST(StatusTest, StreamOperator) {
  Status s = Status::Error("Stream test");
  std::stringstream ss;
  ss << s;
  EXPECT_EQ(ss.str(), "[100-kError]{Stream test}");
}

TEST(StatusTest, StorageError) {
  Status s = Status::StorageError("Storage is corrupted");
  std::stringstream ss;
  ss << s;
  EXPECT_EQ(ss.str(), "[200-kStorageError]{Storage is corrupted}");
}

}  // namespace halo::common::base
