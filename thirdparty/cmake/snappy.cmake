# snappy third-party integration
# Reference: https://github.com/google/snappy

thirdparty_build_cmake_library("snappy"
    CMAKE_ARGS
        "-DCMAKE_CXX_FLAGS=-fvisibility=default"
        -DSNAPPY_BUILD_TESTS=OFF
        -DSNAPPY_BUILD_BENCHMARKS=OFF
        -DSNAPPY_INSTALL=ON
        -DSNAPPY_REQUIRE_AVX=OFF
        -DSNAPPY_REQUIRE_AVX2=OFF
    FILE_REPLACEMENTS
        "CMakeLists.txt"
        "string(REGEX REPLACE \"-frtti\" \"\" CMAKE_CXX_FLAGS \"\${CMAKE_CXX_FLAGS}\")\n  set(CMAKE_CXX_FLAGS \"\${CMAKE_CXX_FLAGS} -fno-rtti\")"
        "# RTTI disabled by default, but we override with CMAKE_CXX_FLAGS"
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/snappy/lib/cmake/Snappy/SnappyConfig.cmake"
        "${THIRDPARTY_INSTALL_DIR}/snappy/lib/libsnappy.a"
        "${THIRDPARTY_INSTALL_DIR}/snappy/include/snappy.h"
)

set(SNAPPY_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/snappy")
get_filename_component(SNAPPY_INSTALL_DIR "${SNAPPY_INSTALL_DIR}" ABSOLUTE)

find_package(Snappy CONFIG REQUIRED)
    