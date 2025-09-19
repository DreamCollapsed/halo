# fast-float third-party integration
# Reference: https://github.com/fastfloat/fast_float

thirdparty_build_cmake_library("fast-float"
    EXTRACT_PATTERN "${THIRDPARTY_SRC_DIR}/fast_float-*"
    CMAKE_ARGS
        -DFASTFLOAT_TEST=OFF
        -DFASTFLOAT_SANITIZE=OFF
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/fast-float/share/cmake/FastFloat/FastFloatConfig.cmake"
        "${THIRDPARTY_INSTALL_DIR}/fast-float/include/fast_float/fast_float.h"
)

find_package(FastFloat CONFIG REQUIRED)
