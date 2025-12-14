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

TEST(StatusTest, AllFactoryMethodsDefaults) {
  // Test OK
  {
    Status s = Status::OK();
    EXPECT_TRUE(s.ok());
    EXPECT_EQ(s.code(), Status::Code::kOk);
    EXPECT_EQ(s.message(), "OK");
    EXPECT_EQ(s.toString(), "[0-kOk]{OK}");
  }

  // Test Error
  {
    Status s = Status::Error();
    EXPECT_FALSE(s.ok());
    EXPECT_EQ(s.code(), Status::Code::kError);
    EXPECT_EQ(s.message(), "Error");
    EXPECT_EQ(s.toString(), "[100-kError]{Error}");
  }

  // Test Invalid
  {
    Status s = Status::Invalid();
    EXPECT_FALSE(s.ok());
    EXPECT_EQ(s.code(), Status::Code::kInvalid);
    EXPECT_EQ(s.message(), "Invalid");
    EXPECT_EQ(s.toString(), "[101-kInvalid]{Invalid}");
  }

  // Test NotImplemented
  {
    Status s = Status::NotImplemented();
    EXPECT_FALSE(s.ok());
    EXPECT_EQ(s.code(), Status::Code::kNotImplemented);
    EXPECT_EQ(s.message(), "NotImplemented");
    EXPECT_EQ(s.toString(), "[102-kNotImplemented]{NotImplemented}");
  }

  // Test StorageError
  {
    Status s = Status::StorageError();
    EXPECT_FALSE(s.ok());
    EXPECT_EQ(s.code(), Status::Code::kStorageError);
    EXPECT_EQ(s.message(), "StorageError");
    EXPECT_EQ(s.toString(), "[200-kStorageError]{StorageError}");
  }

  // Test QueryExecutorError
  {
    Status s = Status::QueryExecutorError();
    EXPECT_FALSE(s.ok());
    EXPECT_EQ(s.code(), Status::Code::kQueryExecutorError);
    EXPECT_EQ(s.message(), "QueryExecutorError");
    EXPECT_EQ(s.toString(), "[300-kQueryExecutorError]{QueryExecutorError}");
  }

  // Test QueryOptimizerError
  {
    Status s = Status::QueryOptimizerError();
    EXPECT_FALSE(s.ok());
    EXPECT_EQ(s.code(), Status::Code::kQueryOptimizerError);
    EXPECT_EQ(s.message(), "QueryOptimizerError");
    EXPECT_EQ(s.toString(), "[400-kQueryOptimizerError]{QueryOptimizerError}");
  }

  // Test SqlError
  {
    Status s = Status::SqlError();
    EXPECT_FALSE(s.ok());
    EXPECT_EQ(s.code(), Status::Code::kSqlError);
    EXPECT_EQ(s.message(), "SqlError");
    EXPECT_EQ(s.toString(), "[500-kSqlError]{SqlError}");
  }
}

TEST(StatusTest, InvalidCodeToString) {
  Status s = Status::OK();
  // Hack: Modify private code_ member via pointer manipulation to test
  // unreachable default case in codeName() Status layout: Code code_ (uint16),
  // std::string msg_ We assume code_ is at offset 0.
  // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast)
  *reinterpret_cast<uint16_t*>(&s) = 9999;

  EXPECT_EQ(s.code(), static_cast<Status::Code>(9999));
  std::string str = s.toString();
  EXPECT_NE(str.find("Unknown"), std::string::npos);
  EXPECT_EQ(str, "[9999-Unknown]{OK}");
}

}  // namespace halo::common::base
