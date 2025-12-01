#include "common/base/Status.h"

#include <utility>

namespace halo::common::base {

Status::Status(Code code, std::string msg) : code_(code), msg_(std::move(msg)) {
  if (msg_.empty()) {
    msg_ = std::string(findMsg(code));
  }
}

std::string Status::toString() const {
  return "[" + std::to_string(static_cast<CodeType>(code_)) + "-" +
         std::string(codeName(code_)) + "]{" + msg_ + "}";
}

std::ostream& operator<<(std::ostream& ostream, const Status& status) {
  return ostream << status.toString();
}

}  // namespace halo::common::base
