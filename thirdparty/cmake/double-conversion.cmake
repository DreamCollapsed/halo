# double-conversion third-party integration
# Reference: https://github.com/google/double-conversion

# Use the standardized build function for simple CMake libraries
thirdparty_build_cmake_library("double-conversion"
    CMAKE_ARGS
        -DBUILD_TESTING=OFF
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/double-conversion/lib/cmake/double-conversion/double-conversionConfig.cmake"
        "${THIRDPARTY_INSTALL_DIR}/double-conversion/lib/libdouble-conversion.a"
        "${THIRDPARTY_INSTALL_DIR}/double-conversion/include/double-conversion/double-conversion.h"
)
