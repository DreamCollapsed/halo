#include <absl/strings/str_cat.h>
#include <jemalloc/jemalloc.h>
#include <velox/type/Type.h>
#include <velox/vector/BaseVector.h>
#include <velox/vector/SimpleVector.h>

#include <iostream>

int main() {
  std::cout << absl::StrCat("Message: ", "Hello, World!") << '\n';

  // Simple Velox integration test
  try {
    auto int_type = facebook::velox::TypeFactory<
        facebook::velox::TypeKind::INTEGER>::create();
    std::cout << "Velox integration successful! Created INTEGER type: "
              << int_type->toString() << '\n';
  } catch (const std::exception& e) {
    std::cout << "Velox integration error: " << e.what() << '\n';
    return 1;
  }

  return 0;
}
