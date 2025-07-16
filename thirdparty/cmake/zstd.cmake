# zstd third-party integration
# Reference: https://github.com/facebook/zstd

# Use custom setup because zstd's CMake files are in build/cmake subdirectory
thirdparty_check_dependencies("zstd")

# Set up directories
thirdparty_setup_directories("zstd")

# Get directory variables
set(ZSTD_DOWNLOAD_FILE "${THIRDPARTY_DOWNLOAD_DIR}/zstd-${ZSTD_VERSION}.tar.gz")
set(ZSTD_SOURCE_DIR "${THIRDPARTY_SRC_DIR}/zstd")
set(ZSTD_BUILD_DIR "${THIRDPARTY_BUILD_DIR}/zstd")
set(ZSTD_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/zstd")
get_filename_component(ZSTD_INSTALL_DIR "${ZSTD_INSTALL_DIR}" ABSOLUTE)

# Download and extract zstd
thirdparty_download_and_check("${ZSTD_URL}" "${ZSTD_DOWNLOAD_FILE}" "${ZSTD_SHA256}")
thirdparty_extract_and_rename("${ZSTD_DOWNLOAD_FILE}" "${ZSTD_SOURCE_DIR}" "${THIRDPARTY_SRC_DIR}/zstd-*")

# Configure zstd with CMake and optimization flags
# zstd's CMake files are in the build/cmake subdirectory
set(ZSTD_CMAKE_SOURCE_DIR "${ZSTD_SOURCE_DIR}/build/cmake")

thirdparty_get_optimization_flags(_opt_flags)
list(APPEND _opt_flags
    -DCMAKE_INSTALL_PREFIX=${ZSTD_INSTALL_DIR}
    -DZSTD_BUILD_STATIC=ON
    -DZSTD_BUILD_SHARED=OFF
    -DZSTD_BUILD_PROGRAMS=OFF
    -DZSTD_BUILD_TESTS=OFF
    -DZSTD_BUILD_CONTRIB=OFF
    -DZSTD_MULTITHREAD_SUPPORT=ON
    -DZSTD_LEGACY_SUPPORT=OFF
)

thirdparty_cmake_configure("${ZSTD_CMAKE_SOURCE_DIR}" "${ZSTD_BUILD_DIR}"
    VALIDATION_FILES
        "${ZSTD_BUILD_DIR}/CMakeCache.txt"
        "${ZSTD_BUILD_DIR}/Makefile"
    CMAKE_ARGS
        ${_opt_flags}
)

thirdparty_cmake_install("${ZSTD_BUILD_DIR}" "${ZSTD_INSTALL_DIR}"
    VALIDATION_FILES
        "${ZSTD_INSTALL_DIR}/lib/cmake/zstd/zstdConfig.cmake"
        "${ZSTD_INSTALL_DIR}/lib/libzstd.a"
        "${ZSTD_INSTALL_DIR}/include/zstd.h"
)

# Export zstd to global scope
if(EXISTS "${ZSTD_INSTALL_DIR}/lib/cmake/zstd/zstdConfig.cmake")
    list(APPEND CMAKE_PREFIX_PATH "${ZSTD_INSTALL_DIR}")
    set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" PARENT_SCOPE)
    message(STATUS "zstd found and exported globally: ${ZSTD_INSTALL_DIR}")
else()
    message(WARNING "zstd installation not found at ${ZSTD_INSTALL_DIR}")
endif()
