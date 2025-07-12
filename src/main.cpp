#include <absl/strings/str_cat.h>
#include <jemalloc/jemalloc.h>

#include <iostream>

int main() {
  std::cout << absl::StrCat("Message: ", "Hello, World!") << std::endl;

  // Simple jemalloc verification
  void* ptr = malloc(1000);
  if (ptr && je_malloc_usable_size(ptr) < 0) {
    std::cout << "jemalloc drop-in mode: INACTIVE" << std::endl;
  }
  free(ptr);

  return 0;
}
