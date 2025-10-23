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

set(ZSTD_ROOT "${THIRDPARTY_INSTALL_DIR}/zstd" CACHE PATH "Root of halo-provided zstd" FORCE)
set(ZSTD_INCLUDE_DIR "${THIRDPARTY_INSTALL_DIR}/zstd/include" CACHE PATH "Include dir for halo-provided zstd" FORCE)
set(ZSTD_LIBRARY "${THIRDPARTY_INSTALL_DIR}/zstd/lib/libzstd.a" CACHE FILEPATH "Static zstd library for halo" FORCE)
set(ZSTD_LIBRARY_RELEASE "${THIRDPARTY_INSTALL_DIR}/zstd/lib/libzstd.a" CACHE FILEPATH "Release zstd library for halo" FORCE)
if(NOT DEFINED ZSTD_LIBRARY_DEBUG OR ZSTD_LIBRARY_DEBUG STREQUAL "ZSTD_LIBRARY_DEBUG-NOTFOUND")
    set(ZSTD_LIBRARY_DEBUG "${THIRDPARTY_INSTALL_DIR}/zstd/lib/libzstd.a" CACHE FILEPATH "Debug zstd library (static)" FORCE)
endif()

message(STATUS "[halo:zstd] Using zstd static library at ${ZSTD_LIBRARY}")
