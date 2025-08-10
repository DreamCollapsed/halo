# snappy third-party integration
# Reference: https://github.com/google/snappy

thirdparty_build_cmake_library("snappy"
    CMAKE_ARGS
        -DSNAPPY_BUILD_TESTS=OFF
        -DSNAPPY_BUILD_BENCHMARKS=OFF
        -DSNAPPY_INSTALL=ON
        -DSNAPPY_REQUIRE_AVX=OFF
        -DSNAPPY_REQUIRE_AVX2=OFF
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/snappy/lib/cmake/Snappy/SnappyConfig.cmake"
        "${THIRDPARTY_INSTALL_DIR}/snappy/lib/libsnappy.a"
        "${THIRDPARTY_INSTALL_DIR}/snappy/include/snappy.h"
)

set(SNAPPY_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/snappy")
get_filename_component(SNAPPY_INSTALL_DIR "${SNAPPY_INSTALL_DIR}" ABSOLUTE)

if(EXISTS "${SNAPPY_INSTALL_DIR}/lib/cmake/Snappy/SnappyConfig.cmake")
    find_package(Snappy CONFIG REQUIRED)
    
    message(STATUS "snappy found and exported globally: ${SNAPPY_INSTALL_DIR}")
else()
    message(FATAL_ERROR "snappy installation not found at ${SNAPPY_INSTALL_DIR}")
endif()
