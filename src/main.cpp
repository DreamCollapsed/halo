#include <folly/FBString.h>
#include <folly/Format.h>
#include <iostream>

int main() {
    // Use folly::fbstring
    folly::fbstring hello = "Hello, ";
    folly::fbstring world = "World!";
    folly::fbstring message = hello + world;

    // Use folly::format
    std::cout << folly::format("Message: {}", message).str() << std::endl;

    return 0;
}
