#pragma once

#include "common/base/Status.h"

#include <glog/logging.h>

#include <type_traits>
#include <utility>
#include <variant>

namespace halo::common::base {

template <typename T>
class [[nodiscard]] StatusOr final {
 public:
  // Make friends with other compatible StatusOr<U>
  template <typename U>
  friend class StatusOr;

  // Convenience type traits
  template <typename U>
  static constexpr bool is_status_v =
      std::is_same_v<halo::common::base::Status, std::decay_t<U>>;

  // Tell if `U' is of type `StatusOr<V>'
  template <typename U>
  struct is_status_or : std::false_type {};

  template <typename V>
  struct is_status_or<StatusOr<V>> : std::true_type {};

  template <typename U>
  static constexpr bool is_status_or_v = is_status_or<std::decay_t<U>>::value;

  // Tell if `T' is initializable from `U'.
  template <typename U>
  static constexpr bool is_initializable_v =
      std::is_constructible_v<T, U> && std::is_convertible_v<U, T> &&
      !is_status_or_v<U> && !is_status_v<U>;

  // Assertions
  static_assert(std::is_copy_constructible_v<T> ||
                    std::is_move_constructible_v<T>,
                "T must be copy/move constructible");
  static_assert(!std::is_reference_v<T>, "T must not be of type reference");
  static_assert(!is_status_v<T>, "T must not be of type Status");
  static_assert(!is_status_or_v<T>, "T must not be of type StatusOr");

  StatusOr() : variant_(std::monostate{}) {}

  ~StatusOr() = default;

  // Copy/move construct from `Status'
  // We allow implicit conversion from Status to StatusOr for convenience
  template <typename U>
  explicit StatusOr(U &&status)
    requires(is_status_v<U>)
      : variant_(std::in_place_type<halo::common::base::Status>,
                 std::forward<U>(status)) {}

  // Copy/move construct with a value of any compatible type
  // We allow implicit conversion from T to StatusOr for convenience
  template <typename U>
  explicit StatusOr(U &&value)
    requires(is_initializable_v<U>)
      : variant_(std::in_place_type<T>, std::forward<U>(value)) {}

  explicit StatusOr(T &&value)
      : variant_(std::in_place_type<T>, std::move(value)) {}

  // Copy constructor
  StatusOr(const StatusOr &rhs) = default;

  // Copy construct from a lvalue of `StatusOr<U>'
  template <typename U>
  explicit StatusOr(const StatusOr<U> &rhs)
    requires(is_initializable_v<U>)
  {
    if (rhs.hasValue()) {
      variant_.template emplace<T>(rhs.value());
    } else if (rhs.hasStatus()) {
      variant_.template emplace<halo::common::base::Status>(rhs.status());
    } else {
      variant_ = std::monostate{};
    }
  }

  // Copy assignment operator
  StatusOr &operator=(const StatusOr &rhs) = default;

  // Move constructor
  StatusOr(StatusOr &&rhs) noexcept : variant_(std::move(rhs.variant_)) {
    rhs.variant_ = std::monostate{};
  }

  // Move construct from a rvalue of StatusOr<U>
  template <typename U>
  explicit StatusOr(StatusOr<U> &&rhs) noexcept
    requires(is_initializable_v<U>)
  {
    if (rhs.hasValue()) {
      variant_.template emplace<T>(std::move(rhs).value());
    } else if (rhs.hasStatus()) {
      variant_.template emplace<halo::common::base::Status>(
          std::move(rhs).status());
    } else {
      variant_ = std::monostate{};
    }
  }

  // Move assignment operator
  StatusOr &operator=(StatusOr &&rhs) noexcept {
    if (&rhs == this) {
      return *this;
    }
    variant_ = std::move(rhs.variant_);
    rhs.variant_ = std::monostate{};
    return *this;
  }

  // Move assignment operator from a rvalue of `StatusOr<U>'
  template <typename U>
  StatusOr &operator=(StatusOr<U> &&rhs) noexcept
    requires(is_initializable_v<U>)
  {
    if (rhs.hasValue()) {
      variant_.template emplace<T>(std::move(rhs).value());
    } else if (rhs.hasStatus()) {
      variant_.template emplace<halo::common::base::Status>(
          std::move(rhs).status());
    } else {
      variant_ = std::monostate{};
    }
    return *this;
  }

  // Move assignment operator from a rvalue of any compatible type with `T'
  template <typename U>
  StatusOr &operator=(U &&value) noexcept
    requires(is_initializable_v<U>)
  {
    variant_.template emplace<T>(std::forward<U>(value));
    return *this;
  }

  // Copy assign from a lvalue of `Status'
  StatusOr &operator=(const halo::common::base::Status &status) {
    variant_.template emplace<halo::common::base::Status>(status);
    return *this;
  }

  // Move assign from a rvalue of `Status'
  StatusOr &operator=(halo::common::base::Status &&status) noexcept {
    variant_.template emplace<halo::common::base::Status>(std::move(status));
    return *this;
  }

  [[nodiscard]] bool ok() const { return hasValue(); }

  explicit operator bool() const { return ok(); }

  [[nodiscard]] halo::common::base::Status status() const & {
    if (hasStatus()) {
      return std::get<halo::common::base::Status>(variant_);
    }
    if (hasValue()) {
      return halo::common::base::Status::OK();
    }
    return halo::common::base::Status::Error("StatusOr is void");
  }

  [[nodiscard]] halo::common::base::Status status() && {
    if (hasStatus()) {
      auto status = std::move(std::get<halo::common::base::Status>(variant_));
      variant_ = std::monostate{};
      return status;
    }
    if (hasValue()) {
      return halo::common::base::Status::OK();
    }
    return halo::common::base::Status::Error("StatusOr is void");
  }

  [[nodiscard]] T &value() & {
    CHECK(ok()) << "StatusOr does not contain a value: " << status().toString();
    return std::get<T>(variant_);
  }

  [[nodiscard]] const T &value() const & {
    CHECK(ok()) << "StatusOr does not contain a value: " << status().toString();
    return std::get<T>(variant_);
  }

  [[nodiscard]] T value() && {
    CHECK(ok()) << "StatusOr does not contain a value: " << status().toString();
    auto value = std::move(std::get<T>(variant_));
    variant_ = std::monostate{};
    return value;
  }

 private:
  [[nodiscard]] bool hasValue() const {
    return std::holds_alternative<T>(variant_);
  }

  [[nodiscard]] bool hasStatus() const {
    return std::holds_alternative<halo::common::base::Status>(variant_);
  }

  [[nodiscard]] bool isVoid() const {
    return std::holds_alternative<std::monostate>(variant_);
  }

  std::variant<std::monostate, halo::common::base::Status, T> variant_;
};

}  // namespace halo::common::base
