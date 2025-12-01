#include "common/base/StatusOr.h"

#include <gtest/gtest.h>

namespace halo::common::base {

TEST(StatusOrTest, ValueConstructor) {
  StatusOr<int> so(42);
  EXPECT_TRUE(so.ok());
  EXPECT_EQ(so.value(), 42);
}

TEST(StatusOrTest, StatusConstructor) {
  StatusOr<int> so(Status::Error("Bad"));
  EXPECT_FALSE(so.ok());
  EXPECT_EQ(so.status().code(), Status::Code::kError);
  EXPECT_EQ(so.status().message(), "Bad");
}

TEST(StatusOrTest, CopyConstructorValue) {
  StatusOr<int> so1(42);
  StatusOr<int> so2(  // NOLINT(performance-unnecessary-copy-initialization)
      so1);
  EXPECT_TRUE(so2.ok());
  EXPECT_EQ(so2.value(), 42);
}

TEST(StatusOrTest, CopyConstructorStatus) {
  StatusOr<int> so1(Status::Error("Bad"));
  StatusOr<int> so2(  // NOLINT(performance-unnecessary-copy-initialization)
      so1);
  EXPECT_FALSE(so2.ok());
  EXPECT_EQ(so2.status().code(), Status::Code::kError);
}

TEST(StatusOrTest, MoveConstructorValue) {
  StatusOr<std::string> so1(std::string("hello"));
  StatusOr<std::string> so2(std::move(so1));
  EXPECT_TRUE(so2.ok());
  EXPECT_EQ(so2.value(), "hello");
}

TEST(StatusOrTest, AssignmentValue) {
  StatusOr<int> so1(42);
  StatusOr<int> so2(0);
  so2 = so1;
  EXPECT_TRUE(so2.ok());
  EXPECT_EQ(so2.value(), 42);
}

TEST(StatusOrTest, AssignmentStatus) {
  StatusOr<int> so1(Status::Error("Bad"));
  StatusOr<int> so2(0);
  so2 = so1;
  EXPECT_FALSE(so2.ok());
  EXPECT_EQ(so2.status().code(), Status::Code::kError);
}

TEST(StatusOrTest, StatusReference) {
  StatusOr<int> so(Status::Error("Bad"));
  const auto& s = so.status();
  EXPECT_EQ(s.code(), Status::Code::kError);
}

TEST(StatusOrTest, ValueReference) {
  StatusOr<int> so(42);
  EXPECT_EQ(so.value(), 42);
  so.value() = 43;
  EXPECT_EQ(so.value(), 43);
}

}  // namespace halo::common::base
