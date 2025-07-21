# snappy third-party integration
# Reference: https://github.com/google/snappy

# Use the standardized build function for simple CMake libraries
thirdparty_build_cmake_library("snappy"
    CMAKE_ARGS
        -DSNAPPY_BUILD_TESTS=OFF
        -DSNAPPY_BUILD_BENCHMARKS=OFF
        -DSNAPPY_INSTALL=ON
        -DSNAPPY_REQUIRE_AVX=OFF
        -DSNAPPY_REQUIRE_AVX2=OFF
        -DBUILD_SHARED_LIBS=OFF
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/snappy/lib/cmake/Snappy/SnappyConfig.cmake"
        "${THIRDPARTY_INSTALL_DIR}/snappy/lib/libsnappy.a"
        "${THIRDPARTY_INSTALL_DIR}/snappy/include/snappy.h"
)

# Additional snappy-specific setup (remove the warning)
set(SNAPPY_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/snappy")
get_filename_component(SNAPPY_INSTALL_DIR "${SNAPPY_INSTALL_DIR}" ABSOLUTE)

# No additional warning needed - the standardized function handles this
if(EXISTS "${SNAPPY_INSTALL_DIR}/lib/cmake/Snappy/SnappyConfig.cmake")
    list(APPEND CMAKE_PREFIX_PATH "${SNAPPY_INSTALL_DIR}")
    set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" PARENT_SCOPE)
    set(Snappy_DIR "${SNAPPY_INSTALL_DIR}/lib/cmake/Snappy" CACHE PATH "Path to installed snappy cmake config" FORCE)
    
    # Import snappy package immediately
    find_package(Snappy REQUIRED CONFIG QUIET)
    
    message(STATUS "snappy found and exported globally: ${SNAPPY_INSTALL_DIR}")
else()
    message(WARNING "snappy installation not found at ${SNAPPY_INSTALL_DIR}")
endif()
