# lz4 third-party integration
# Reference: https://github.com/lz4/lz4

# Use the standardized build function for lz4
# Note: lz4 has CMake files in build/cmake subdirectory
thirdparty_build_cmake_library("lz4"
    SOURCE_SUBDIR "build/cmake"
    VALIDATION_FILES
        "${LZ4_INSTALL_DIR}/lib/liblz4.a"
        "${LZ4_INSTALL_DIR}/include/lz4.h"
    CMAKE_ARGS
        -DLZ4_BUILD_CLI=OFF
        -DLZ4_BUILD_LEGACY_LIBS=OFF
        -DLZ4_BUNDLE_MODE=OFF
        -DLZ4_POSITION_INDEPENDENT_CODE=ON
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
