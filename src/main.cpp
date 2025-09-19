#include <absl/strings/str_cat.h>
#include <jemalloc/jemalloc.h>
#include <velox/type/Type.h>
#include <velox/vector/BaseVector.h>
#include <velox/vector/SimpleVector.h>

#include <iostream>

int main() {
  std::cout << absl::StrCat("Message: ", "Hello, World!") << std::endl;

  // Simple jemalloc verification
  void* ptr = malloc(1000);
  if (ptr && je_malloc_usable_size(ptr) < 0) {
    std::cout << "jemalloc drop-in mode: INACTIVE" << std::endl;
  }
  free(ptr);

  // Simple Velox integration test
  try {
    auto intType = facebook::velox::TypeFactory<
        facebook::velox::TypeKind::INTEGER>::create();
    std::cout << "Velox integration successful! Created INTEGER type: "
              << intType->toString() << std::endl;
  } catch (const std::exception& e) {
    std::cout << "Velox integration error: " << e.what() << std::endl;
    return 1;
  }

  return 0;
}
