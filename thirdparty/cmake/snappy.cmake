# snappy third-party integration
# Reference: https://github.com/google/snappy

# Check dependencies (snappy has no dependencies)
thirdparty_check_dependencies("snappy")

# Set up directories (variables from ComponentsInfo.cmake)
set(SNAPPY_NAME "snappy")
set(SNAPPY_DOWNLOAD_FILE "${THIRDPARTY_DOWNLOAD_DIR}/snappy-${SNAPPY_VERSION}.tar.gz")
set(SNAPPY_SOURCE_DIR "${THIRDPARTY_SRC_DIR}/${SNAPPY_NAME}")
set(SNAPPY_BUILD_DIR "${THIRDPARTY_BUILD_DIR}/${SNAPPY_NAME}")
set(SNAPPY_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/${SNAPPY_NAME}")

# Make sure the installation directory is absolute
get_filename_component(SNAPPY_INSTALL_DIR "${SNAPPY_INSTALL_DIR}" ABSOLUTE)

# Download and extract snappy
thirdparty_download_and_check("${SNAPPY_URL}" "${SNAPPY_DOWNLOAD_FILE}" "${SNAPPY_SHA256}")
thirdparty_extract_and_rename("${SNAPPY_DOWNLOAD_FILE}" "${SNAPPY_SOURCE_DIR}" "${THIRDPARTY_SRC_DIR}/snappy-*")

# Configure snappy with CMake and optimization flags
thirdparty_get_optimization_flags(_opt_flags)
list(APPEND _opt_flags
    -DCMAKE_INSTALL_PREFIX=${SNAPPY_INSTALL_DIR}
    -DSNAPPY_BUILD_TESTS=OFF
    -DSNAPPY_BUILD_BENCHMARKS=OFF
    -DSNAPPY_INSTALL=ON
    -DSNAPPY_REQUIRE_AVX=OFF
    -DSNAPPY_REQUIRE_AVX2=OFF
    -DBUILD_SHARED_LIBS=OFF
)

# Configure the project
thirdparty_cmake_configure("${SNAPPY_SOURCE_DIR}" "${SNAPPY_BUILD_DIR}"
    VALIDATION_FILES
        "${SNAPPY_BUILD_DIR}/CMakeCache.txt"
        "${SNAPPY_BUILD_DIR}/Makefile"
    CMAKE_ARGS
        ${_opt_flags}
)

# Build and install snappy
thirdparty_cmake_install("${SNAPPY_BUILD_DIR}" "${SNAPPY_INSTALL_DIR}"
    VALIDATION_FILES
        "${SNAPPY_INSTALL_DIR}/lib/cmake/Snappy/SnappyConfig.cmake"
        "${SNAPPY_INSTALL_DIR}/lib/libsnappy.a"
        "${SNAPPY_INSTALL_DIR}/include/snappy.h"
)

# Export snappy to global scope
if(EXISTS "${SNAPPY_INSTALL_DIR}/lib/cmake/Snappy/SnappyConfig.cmake")
    list(APPEND CMAKE_PREFIX_PATH "${SNAPPY_INSTALL_DIR}")
    set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" PARENT_SCOPE)
    set(Snappy_DIR "${SNAPPY_INSTALL_DIR}/lib/cmake/Snappy" CACHE PATH "Path to installed snappy cmake config" FORCE)
    message(STATUS "snappy found and exported globally: ${SNAPPY_INSTALL_DIR}")
else()
    message(WARNING "snappy installation not found at ${SNAPPY_INSTALL_DIR}")
endif()
