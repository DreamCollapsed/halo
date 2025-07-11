# gflags third-party integration
# Reference: https://github.com/gflags/gflags

# Check dependencies (gflags has no dependencies)
thirdparty_check_dependencies("gflags")

# Set up directories (variables from ComponentsInfo.cmake)
set(GFLAGS_NAME "gflags")
set(GFLAGS_DOWNLOAD_FILE "${THIRDPARTY_DOWNLOAD_DIR}/gflags-${GFLAGS_VERSION}.tar.gz")
set(GFLAGS_SOURCE_DIR "${THIRDPARTY_SRC_DIR}/${GFLAGS_NAME}")
set(GFLAGS_BUILD_DIR "${THIRDPARTY_BUILD_DIR}/${GFLAGS_NAME}")
set(GFLAGS_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/${GFLAGS_NAME}")

# Make sure the installation directory is absolute
get_filename_component(GFLAGS_INSTALL_DIR "${GFLAGS_INSTALL_DIR}" ABSOLUTE)

# Download and extract gflags
thirdparty_download_and_check("${GFLAGS_URL}" "${GFLAGS_DOWNLOAD_FILE}" "${GFLAGS_SHA256}")

thirdparty_extract_and_rename("${GFLAGS_DOWNLOAD_FILE}" "${GFLAGS_SOURCE_DIR}" "${THIRDPARTY_SRC_DIR}/gflags-*")

# Configure gflags with CMake
# Patch the CMakeLists.txt to use a higher minimum version
file(READ "${GFLAGS_SOURCE_DIR}/CMakeLists.txt" _cmake_content)
string(REPLACE "cmake_minimum_required (VERSION 3.0.2 FATAL_ERROR)" 
               "cmake_minimum_required (VERSION 3.25 FATAL_ERROR)" 
               _cmake_content "${_cmake_content}")
file(WRITE "${GFLAGS_SOURCE_DIR}/CMakeLists.txt" "${_cmake_content}")

# Configure gflags with CMake and optimization flags
thirdparty_get_optimization_flags(_opt_flags)
list(APPEND _opt_flags
    -DCMAKE_INSTALL_PREFIX=${GFLAGS_INSTALL_DIR}
    -DBUILD_STATIC_LIBS=ON
    -DBUILD_TESTING=OFF
    -DINSTALL_HEADERS=ON
    -DREGISTER_INSTALL_PREFIX=OFF
    -DGFLAGS_NAMESPACE=gflags
)

thirdparty_cmake_configure("${GFLAGS_SOURCE_DIR}" "${GFLAGS_BUILD_DIR}"
    VALIDATION_FILES
        "${GFLAGS_BUILD_DIR}/CMakeCache.txt"
        "${GFLAGS_BUILD_DIR}/Makefile"
    ${_opt_flags}
)

# Build and install gflags
thirdparty_cmake_install("${GFLAGS_BUILD_DIR}" "${GFLAGS_INSTALL_DIR}"
    VALIDATION_FILES
        "${GFLAGS_INSTALL_DIR}/lib/cmake/gflags/gflags-config.cmake"
        "${GFLAGS_INSTALL_DIR}/lib/libgflags.a"
        "${GFLAGS_INSTALL_DIR}/include/gflags/gflags.h"
        "${GFLAGS_INSTALL_DIR}/include/gflags/gflags_declare.h"
)

# Export gflags to global scope with namespace support
if(EXISTS "${GFLAGS_INSTALL_DIR}/lib/cmake/gflags/gflags-config.cmake")
    list(APPEND CMAKE_PREFIX_PATH "${GFLAGS_INSTALL_DIR}")
    set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" PARENT_SCOPE)
    set(gflags_DIR "${GFLAGS_INSTALL_DIR}/lib/cmake/gflags" CACHE PATH "Path to installed gflags cmake config" FORCE)
    # Enable namespace support for gflags
    set(GFLAGS_USE_TARGET_NAMESPACE TRUE CACHE BOOL "Use gflags:: namespace" FORCE)
    message(STATUS "gflags found and exported globally with namespace: ${GFLAGS_INSTALL_DIR}")
else()
    message(WARNING "gflags installation not found at ${GFLAGS_INSTALL_DIR}")
endif()
