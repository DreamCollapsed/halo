#include <absl/strings/str_cat.h>

#include <iostream>

int main() {
  std::cout << absl::StrCat("Message: ", "Hello, World!") << std::endl;
  return 0;
}
