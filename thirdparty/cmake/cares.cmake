# c-ares third-party integration
# Reference: https://c-ares.org/
# Build static library only, disable tests and shared libs.

thirdparty_build_cmake_library("cares"
    EXTRACT_PATTERN "${THIRDPARTY_SRC_DIR}/c-ares-*"
    CMAKE_ARGS
        -DCARES_STATIC=ON
        -DCARES_SHARED=OFF
        -DCARES_STATIC_PIC=ON
        -DCARES_BUILD_TOOLS=OFF
        -DCARES_BUILD_TESTS=OFF
        -DCARES_INSTALL=ON
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/cares/lib/libcares.a"
        "${THIRDPARTY_INSTALL_DIR}/cares/include/ares.h"
)

find_package(c-ares CONFIG REQUIRED)
