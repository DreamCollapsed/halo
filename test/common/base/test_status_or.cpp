#include <gtest/gtest.h>

#include <vector>

import halo.common;

namespace halo::common::base {

class StatusOrTest : public ::testing::Test {
 protected:
  static StatusOr<int> CreateStatusOrWithValue(int value) { return value; }

  static StatusOr<int> CreateStatusOrWithStatus() {
    return Status::StorageError("storage Error occurred");
  }

  static StatusOr<std::vector<int>> CreateStatusOrWithVector() {
    return std::vector<int>(10);
  }

  static StatusOr<int> CreateStatusOrWithCastValue() { return 103.0F; }
};

TEST_F(StatusOrTest, ValueConstructor) {
  StatusOr<int> so(42);
  EXPECT_TRUE(so.ok());
  EXPECT_EQ(so.value(), 42);
}

TEST_F(StatusOrTest, StatusConstructor) {
  StatusOr<int> so(Status::Error("Bad"));
  EXPECT_FALSE(so.ok());
  EXPECT_EQ(so.status().code(), Status::Code::kError);
  EXPECT_EQ(so.status().message(), "Bad");
}

TEST_F(StatusOrTest, CopyConstructorValue) {
  StatusOr<int> so1(42);
  StatusOr<int> so2(  // NOLINT(performance-unnecessary-copy-initialization)
      so1);
  EXPECT_TRUE(so2.ok());
  EXPECT_EQ(so2.value(), 42);
}

TEST_F(StatusOrTest, CopyConstructorStatus) {
  StatusOr<int> so1(Status::Error("Bad"));
  StatusOr<int> so2(  // NOLINT(performance-unnecessary-copy-initialization)
      so1);
  EXPECT_FALSE(so2.ok());
  EXPECT_EQ(so2.status().code(), Status::Code::kError);
}

TEST_F(StatusOrTest, MoveConstructorValue) {
  StatusOr<std::string> so1(std::string("hello"));
  StatusOr<std::string> so2(std::move(so1));
  EXPECT_TRUE(so2.ok());
  EXPECT_EQ(so2.value(), "hello");
}

TEST_F(StatusOrTest, AssignmentValue) {
  StatusOr<int> so1(42);
  StatusOr<int> so2(0);
  so2 = so1;
  EXPECT_TRUE(so2.ok());
  EXPECT_EQ(so2.value(), 42);
}

TEST_F(StatusOrTest, AssignmentStatus) {
  StatusOr<int> so1(Status::Error("Bad"));
  StatusOr<int> so2(0);
  so2 = so1;
  EXPECT_FALSE(so2.ok());
  EXPECT_EQ(so2.status().code(), Status::Code::kError);
}

TEST_F(StatusOrTest, StatusReference) {
  StatusOr<int> so(Status::Error("Bad"));
  const auto& s = so.status();
  EXPECT_FALSE(s.ok());
  EXPECT_EQ(s.code(), Status::Code::kError);
}

TEST_F(StatusOrTest, ValueReference) {
  StatusOr<int> so(42);
  EXPECT_EQ(so.value(), 42);
  so.value() = 43;
  EXPECT_EQ(so.value(), 43);
}

TEST_F(StatusOrTest, ImplicitReturn) {
  auto so_val = CreateStatusOrWithValue(100);
  EXPECT_TRUE(so_val.ok());
  EXPECT_EQ(so_val.value(), 100);

  auto so_status = CreateStatusOrWithStatus();
  EXPECT_FALSE(so_status.ok());
  EXPECT_EQ(so_status.status().code(), Status::Code::kStorageError);
  EXPECT_EQ(so_status.status().message(), "storage Error occurred");

  auto so_vector = CreateStatusOrWithVector();
  EXPECT_TRUE(so_vector.ok());
  EXPECT_EQ(so_vector.value().size(), 10);

  auto so_val1 = CreateStatusOrWithCastValue();
  EXPECT_TRUE(so_val1.ok());
  EXPECT_EQ(so_val1.value(), 103);
}

}  // namespace halo::common::base
