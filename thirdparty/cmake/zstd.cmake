# zstd third-party integration
# Reference: https://github.com/facebook/zstd

thirdparty_build_cmake_library("zstd"
    SOURCE_SUBDIR "build/cmake"
    CMAKE_ARGS
        -DZSTD_BUILD_STATIC=ON
        -DZSTD_BUILD_SHARED=OFF
        -DZSTD_BUILD_PROGRAMS=OFF
        -DZSTD_BUILD_TESTS=OFF
        -DZSTD_BUILD_CONTRIB=OFF
        -DZSTD_MULTITHREAD_SUPPORT=ON
        -DZSTD_LEGACY_SUPPORT=ON
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/zstd/lib/cmake/zstd/zstdConfig.cmake"
        "${THIRDPARTY_INSTALL_DIR}/zstd/lib/libzstd.a"
        "${THIRDPARTY_INSTALL_DIR}/zstd/include/zstd.h"
)

find_package(zstd CONFIG REQUIRED)
