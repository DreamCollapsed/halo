#pragma once

#include <cstdint>
#include <ostream>
#include <string>
#include <string_view>

namespace halo::common::base {

// Define all status codes in one place using an X-Macro
// Format: ENTRY(EnumName, FunctionName, Code, Message)
#define HALO_STATUS_MAP(STATUS_ENTRY)                                  \
  /* 0: OK */                                                          \
  STATUS_ENTRY(kOk, OK, 0, "OK")                                       \
                                                                       \
  /* 1xx: General Errors */                                            \
  STATUS_ENTRY(kError, Error, 100, "Error")                            \
  STATUS_ENTRY(kInvalid, Invalid, 101, "Invalid")                      \
  STATUS_ENTRY(kNotImplemented, NotImplemented, 102, "NotImplemented") \
                                                                       \
  /* 2xx: Storage Errors */                                            \
  STATUS_ENTRY(kStorageError, StorageError, 200, "StorageError")       \
                                                                       \
  /* 3xx: Query Executor Errors */                                     \
  STATUS_ENTRY(kQueryExecutorError, QueryExecutorError, 300,           \
               "QueryExecutorError")                                   \
                                                                       \
  /* 4xx: Query Optimizer Errors */                                    \
  STATUS_ENTRY(kQueryOptimizerError, QueryOptimizerError, 400,         \
               "QueryOptimizerError")                                  \
                                                                       \
  /* 5xx: SQL Errors */                                                \
  STATUS_ENTRY(kSqlError, SqlError, 500, "SqlError")

class [[nodiscard]] Status final {
 public:
  using CodeType = std::uint16_t;
  enum class Code : CodeType {
#define STATUS_ENTRY(enum_name, func_name, code, msg) enum_name = (code),
    HALO_STATUS_MAP(STATUS_ENTRY)
#undef STATUS_ENTRY
  };

  // Factory methods
#define STATUS_ENTRY(enum_name, func_name, code, msg)   \
  static Status func_name(std::string message = "") {   \
    return Status(Code::enum_name, std::move(message)); \
  }
  HALO_STATUS_MAP(STATUS_ENTRY)
#undef STATUS_ENTRY

 private:
  static constexpr std::string_view findMsg(Code code) {
    switch (code) {
#define STATUS_ENTRY(enum_name, func_name, code_val, msg_str) \
  case Code::enum_name:                                       \
    return msg_str;
      HALO_STATUS_MAP(STATUS_ENTRY)
#undef STATUS_ENTRY
      default:
        return "Unknown";
    }
  }

  static constexpr std::string_view codeName(Code code) {
    switch (code) {
#define STATUS_ENTRY(enum_name, func_name, code_val, msg_str) \
  case Code::enum_name:                                       \
    return #enum_name;
      HALO_STATUS_MAP(STATUS_ENTRY)
#undef STATUS_ENTRY
      default:
        return "Unknown";
    }
  }

 public:
  Status() = default;
  Status(const Status&) = default;
  Status(Status&&) = default;
  Status& operator=(const Status&) = default;
  Status& operator=(Status&&) = default;
  ~Status() = default;

  [[nodiscard]] bool ok() const { return code_ == Code::kOk; }
  [[nodiscard]] Code code() const { return code_; }
  [[nodiscard]] const std::string& message() const { return msg_; }

  [[nodiscard]] std::string toString() const;

 private:
  explicit Status(Code code, std::string msg = "");

  Code code_ = Code::kOk;
  std::string msg_ = "OK";
};

std::ostream& operator<<(std::ostream& ostream, const Status& status);

// Clean up macro to avoid polluting global namespace
#undef HALO_STATUS_MAP

}  // namespace halo::common::base
