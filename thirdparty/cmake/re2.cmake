# re2 third-party integration
# Reference: https://github.com/google/re2
# We build static library only, disable tests/tools/benchmark.

thirdparty_build_cmake_library("re2"
    CMAKE_ARGS
        -DRE2_BUILD_TESTING=OFF
        -DRE2_BUILD_TESTS=OFF
        -DRE2_BUILD_BENCHMARK=OFF
        -DRE2_BUILD_TOOLS=OFF
        -DRE2_INSTALL=ON
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/re2/lib/cmake/re2/re2Config.cmake"
        "${THIRDPARTY_INSTALL_DIR}/re2/include/re2/re2.h"
        "${THIRDPARTY_INSTALL_DIR}/re2/lib/libre2.a"
)

halo_find_package(re2 CONFIG REQUIRED)
