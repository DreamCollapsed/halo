#include <folly/FBString.h>
#include <folly/Format.h>
#include <iostream>

int main() {
    // 使用folly::fbstring
    folly::fbstring hello = "Hello, ";
    folly::fbstring world = "World!";
    folly::fbstring message = hello + world;

    // 使用folly::format
    std::cout << folly::format("Message: {}", message).str() << std::endl;

    return 0;
}
