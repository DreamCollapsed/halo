# lz4 third-party integration
# Reference: https://github.com/lz4/lz4

# Use the standardized build function for lz4
# Note: lz4 has CMake files in build/cmake subdirectory and depends on zstd
thirdparty_build_cmake_library("lz4"
    DEPENDENCIES "zstd"
    SOURCE_SUBDIR "build/cmake"
    CMAKE_ARGS
        -DLZ4_BUILD_CLI=OFF
        -DLZ4_BUILD_LEGACY_LZ4C=OFF
        -DLZ4_BUNDLED_MODE=OFF
        -DLZ4_POSITION_INDEPENDENT_LIB=ON
        -DLZ4_BUILD_TESTS=OFF
        -DZSTD_ROOT=${THIRDPARTY_INSTALL_DIR}/zstd
        -DZSTD_DIR=${THIRDPARTY_INSTALL_DIR}/zstd/lib/cmake/zstd
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/lz4/lib/cmake/lz4/lz4Config.cmake"
        "${THIRDPARTY_INSTALL_DIR}/lz4/lib/liblz4.a"
        "${THIRDPARTY_INSTALL_DIR}/lz4/include/lz4.h"
)

# Additional lz4-specific setup
set(LZ4_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/lz4")
get_filename_component(LZ4_INSTALL_DIR "${LZ4_INSTALL_DIR}" ABSOLUTE)

if(EXISTS "${LZ4_INSTALL_DIR}/lib/cmake/lz4/lz4Config.cmake")
    set(lz4_DIR "${LZ4_INSTALL_DIR}/lib/cmake/lz4" CACHE PATH "Path to installed lz4 cmake config" FORCE)
    
    # Import lz4 package immediately
    find_package(lz4 REQUIRED CONFIG QUIET)
    
    message(STATUS "lz4 found and exported globally: ${LZ4_INSTALL_DIR}")
else()
    message(WARNING "lz4 installation not found at ${LZ4_INSTALL_DIR}")
endif()
