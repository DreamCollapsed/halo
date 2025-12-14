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

  template <typename T>
  static StatusOr<T> CreateVoidStatusOr(T val) {
    StatusOr<T> origin(val);
    StatusOr<T> moved(std::move(origin));
    return origin;  // NOLINT(bugprone-use-after-move,clang-analyzer-cplusplus.Move)
  }
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

TEST_F(StatusOrTest, DefaultConstructor) {
  StatusOr<int> so;
  EXPECT_TRUE(so.ok());
  // Default constructed int is 0
  EXPECT_EQ(so.value(), 0);
}

TEST_F(StatusOrTest, CopyConstructorFromCompatible) {
  StatusOr<short> so_short(42);
  StatusOr<int> so_int(so_short);
  EXPECT_TRUE(so_int.ok());
  EXPECT_EQ(so_int.value(), 42);

  StatusOr<short> so_short_err(Status::Error("Bad"));
  StatusOr<int> so_int_err(so_short_err);
  EXPECT_FALSE(so_int_err.ok());
  EXPECT_EQ(so_int_err.status().message(), "Bad");
}

TEST_F(StatusOrTest, MoveConstructorFromCompatible) {
  StatusOr<short> so_short(42);
  StatusOr<int> so_int(std::move(so_short));
  EXPECT_TRUE(so_int.ok());
  EXPECT_EQ(so_int.value(), 42);

  StatusOr<short> so_short_err(Status::Error("Bad"));
  StatusOr<int> so_int_err(std::move(so_short_err));
  EXPECT_FALSE(so_int_err.ok());
  EXPECT_EQ(so_int_err.status().message(), "Bad");
}

TEST_F(StatusOrTest, MoveAssignmentSelf) {
  StatusOr<int> so(42);
  so = std::move(so);  // Self-move
  EXPECT_TRUE(so.ok());
  EXPECT_EQ(so.value(), 42);
}

TEST_F(StatusOrTest, MoveAssignmentFromCompatible) {
  StatusOr<short> so_short(42);
  StatusOr<int> so_int;
  so_int = std::move(so_short);
  EXPECT_TRUE(so_int.ok());
  EXPECT_EQ(so_int.value(), 42);

  StatusOr<short> so_short_err(Status::Error("Bad"));
  so_int = std::move(so_short_err);
  EXPECT_FALSE(so_int.ok());
  EXPECT_EQ(so_int.status().message(), "Bad");
}

TEST_F(StatusOrTest, AssignmentFromValue) {
  StatusOr<int> so;
  so = 100;
  EXPECT_TRUE(so.ok());
  EXPECT_EQ(so.value(), 100);
}

TEST_F(StatusOrTest, AssignmentFromStatus) {
  StatusOr<int> so(42);
  Status status = Status::Error("Something wrong");
  so = status;  // Copy assign status
  EXPECT_FALSE(so.ok());
  EXPECT_EQ(so.status().message(), "Something wrong");

  so = 42;
  so = Status::Error("Moved status");  // Move assign status
  EXPECT_FALSE(so.ok());
  EXPECT_EQ(so.status().message(), "Moved status");
}

TEST_F(StatusOrTest, OperatorBool) {
  StatusOr<int> so(42);
  if (so) {
    SUCCEED();
  } else {
    FAIL() << "Should be true";
  }

  StatusOr<int> so_err(Status::Error("Bad"));
  if (!so_err) {
    SUCCEED();
  } else {
    FAIL() << "Should be false";
  }
}

TEST_F(StatusOrTest, RValueAccessors) {
  StatusOr<int> so(42);
  EXPECT_EQ(std::move(so).value(), 42);

  StatusOr<int> so_err(Status::Error("Bad"));
  EXPECT_EQ(std::move(so_err).status().message(), "Bad");
}

TEST_F(StatusOrTest, OperatorStarAndArrow) {
  StatusOr<int> so(42);
  EXPECT_EQ(*so, 42);

  const StatusOr<int> cso(42);
  EXPECT_EQ(*cso, 42);

  struct Foo {
    int bar = 99;
  };
  StatusOr<Foo> so_foo(Foo{});
  EXPECT_EQ(so_foo->bar, 99);

  const StatusOr<Foo> cso_foo(Foo{});
  EXPECT_EQ(cso_foo->bar, 99);
}

TEST_F(StatusOrTest, VoidStateHandling) {
  // Create a moved-from StatusOr (which should be in monostate/void)
  StatusOr<int> source = CreateVoidStatusOr(42);

  // Now source is void.
  // Test status() on void
  Status s = source.status();
  EXPECT_FALSE(s.ok());
  EXPECT_EQ(s.message(), "StatusOr is void");

  // Test copy constructor from void
  // NOLINTNEXTLINE(performance-unnecessary-copy-initialization)
  StatusOr<int> copy_of_void(source);
  Status s_copy = copy_of_void.status();
  EXPECT_FALSE(s_copy.ok());
  EXPECT_EQ(s_copy.message(), "StatusOr is void");

  // Test move constructor from void (compatible type)
  StatusOr<short> void_short = CreateVoidStatusOr<short>(10);
  StatusOr<int> move_from_void(std::move(void_short));
  Status s_move = move_from_void.status();
  EXPECT_FALSE(s_move.ok());
  EXPECT_EQ(s_move.message(), "StatusOr is void");

  // Test copy constructor from void (compatible type)
  StatusOr<short> void_short2 = CreateVoidStatusOr<short>(10);
  StatusOr<int> copy_from_void(void_short2);
  Status s_copy_compat = copy_from_void.status();
  EXPECT_FALSE(s_copy_compat.ok());
  EXPECT_EQ(s_copy_compat.message(), "StatusOr is void");

  // Test move assignment from void (compatible type)
  StatusOr<short> void_short3 = CreateVoidStatusOr<short>(10);
  StatusOr<int> assign_target;
  assign_target = std::move(void_short3);
  Status s_assign = assign_target.status();
  EXPECT_FALSE(s_assign.ok());
  EXPECT_EQ(s_assign.message(), "StatusOr is void");
}

TEST_F(StatusOrTest, MoveAssignmentSameType) {
  StatusOr<int> so1(42);
  StatusOr<int> so2;
  so2 = std::move(so1);  // Move assignment same type
  EXPECT_TRUE(so2.ok());
  EXPECT_EQ(so2.value(), 42);
}

TEST_F(StatusOrTest, StatusOnValue) {
  StatusOr<int> so(42);
  EXPECT_TRUE(so.status().ok());

  StatusOr<int> so2(42);
  EXPECT_TRUE(std::move(so2).status().ok());
}

TEST_F(StatusOrTest, OperatorStarRValue) {
  StatusOr<int> so(42);
  EXPECT_EQ(*std::move(so), 42);

  const StatusOr<int> cso(42);
  EXPECT_EQ(*std::move(cso), 42);
}

TEST_F(StatusOrTest, RValueStatusOnVoid) {
  StatusOr<int> source = CreateVoidStatusOr(42);

  Status s = std::move(source).status();
  EXPECT_FALSE(s.ok());
  EXPECT_EQ(s.message(), "StatusOr is void");
}

}  // namespace halo::common::base
