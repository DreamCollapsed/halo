# zstd third-party integration
# Reference: https://github.com/facebook/zstd

# Use the standardized build function for zstd
# Note: zstd has CMake files in build/cmake subdirectory
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

# Additional zstd-specific setup
set(ZSTD_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/zstd")
get_filename_component(ZSTD_INSTALL_DIR "${ZSTD_INSTALL_DIR}" ABSOLUTE)

if(EXISTS "${ZSTD_INSTALL_DIR}/lib/cmake/zstd/zstdConfig.cmake")
    set(zstd_DIR "${ZSTD_INSTALL_DIR}/lib/cmake/zstd" CACHE PATH "Path to installed zstd cmake config" FORCE)
    
    # Import zstd package immediately
    find_package(zstd REQUIRED CONFIG QUIET)
    
    message(STATUS "zstd found and exported globally: ${ZSTD_INSTALL_DIR}")
else()
    message(WARNING "zstd installation not found at ${ZSTD_INSTALL_DIR}")
endif()
