# lz4 third-party integration
# Reference: https://github.com/lz4/lz4

# lz4 depends on zstd for enhanced compression
thirdparty_check_dependencies("lz4")

# Set up directories
thirdparty_setup_directories("lz4")

# Get directory variables
set(LZ4_DOWNLOAD_FILE "${THIRDPARTY_DOWNLOAD_DIR}/lz4-${LZ4_VERSION}.tar.gz")
set(LZ4_SOURCE_DIR "${THIRDPARTY_SRC_DIR}/lz4")
set(LZ4_BUILD_DIR "${THIRDPARTY_BUILD_DIR}/lz4")
set(LZ4_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/lz4")
get_filename_component(LZ4_INSTALL_DIR "${LZ4_INSTALL_DIR}" ABSOLUTE)

# Download and extract lz4
thirdparty_download_and_check("${LZ4_URL}" "${LZ4_DOWNLOAD_FILE}" "${LZ4_SHA256}")
thirdparty_extract_and_rename("${LZ4_DOWNLOAD_FILE}" "${LZ4_SOURCE_DIR}" "${THIRDPARTY_SRC_DIR}/lz4-*")

# Configure lz4 with CMake and optimization flags
# lz4's CMake files are in the build/cmake subdirectory
set(LZ4_CMAKE_SOURCE_DIR "${LZ4_SOURCE_DIR}/build/cmake")

thirdparty_get_optimization_flags(_opt_flags)
list(APPEND _opt_flags
    -DCMAKE_INSTALL_PREFIX=${LZ4_INSTALL_DIR}
    -DLZ4_BUILD_CLI=OFF
    -DLZ4_BUILD_LEGACY_LZ4C=OFF
    -DLZ4_BUNDLED_MODE=OFF
    -DLZ4_POSITION_INDEPENDENT_LIB=ON
    -DLZ4_BUILD_TESTS=OFF
)

# Enable zstd support (zstd is guaranteed to be available through dependency management)
message(STATUS "Enabling zstd support for lz4")
list(APPEND _opt_flags
    -DZSTD_ROOT=${THIRDPARTY_INSTALL_DIR}/zstd
    -DZSTD_DIR=${THIRDPARTY_INSTALL_DIR}/zstd/lib/cmake/zstd
)
# Add zstd to CMAKE_PREFIX_PATH for lz4 to find
set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH};${THIRDPARTY_INSTALL_DIR}/zstd")

thirdparty_cmake_configure("${LZ4_CMAKE_SOURCE_DIR}" "${LZ4_BUILD_DIR}"
    VALIDATION_FILES
        "${LZ4_BUILD_DIR}/CMakeCache.txt"
        "${LZ4_BUILD_DIR}/Makefile"
    CMAKE_ARGS
        ${_opt_flags}
)

thirdparty_cmake_install("${LZ4_BUILD_DIR}" "${LZ4_INSTALL_DIR}"
    VALIDATION_FILES
        "${LZ4_INSTALL_DIR}/lib/cmake/lz4/lz4Config.cmake"
        "${LZ4_INSTALL_DIR}/lib/liblz4.a"
        "${LZ4_INSTALL_DIR}/include/lz4.h"
)

# Export lz4 to global scope
if(EXISTS "${LZ4_INSTALL_DIR}/lib/cmake/lz4/lz4Config.cmake")
    list(APPEND CMAKE_PREFIX_PATH "${LZ4_INSTALL_DIR}")
    set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" PARENT_SCOPE)
    message(STATUS "lz4 found and exported globally: ${LZ4_INSTALL_DIR}")
else()
    message(WARNING "lz4 installation not found at ${LZ4_INSTALL_DIR}")
endif()
