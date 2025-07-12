# double-conversion third-party integration
# Reference: https://github.com/google/double-conversion

# Check dependencies (double-conversion has no dependencies)
thirdparty_check_dependencies("double-conversion")

# Set up directories (variables from ComponentsInfo.cmake)
set(DOUBLE_CONVERSION_NAME "double-conversion")
set(DOUBLE_CONVERSION_DOWNLOAD_FILE "${THIRDPARTY_DOWNLOAD_DIR}/double-conversion-${DOUBLE_CONVERSION_VERSION}.tar.gz")
set(DOUBLE_CONVERSION_SOURCE_DIR "${THIRDPARTY_SRC_DIR}/${DOUBLE_CONVERSION_NAME}")
set(DOUBLE_CONVERSION_BUILD_DIR "${THIRDPARTY_BUILD_DIR}/${DOUBLE_CONVERSION_NAME}")
set(DOUBLE_CONVERSION_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/${DOUBLE_CONVERSION_NAME}")

# Make sure the installation directory is absolute
get_filename_component(DOUBLE_CONVERSION_INSTALL_DIR "${DOUBLE_CONVERSION_INSTALL_DIR}" ABSOLUTE)

# Download and extract double-conversion
thirdparty_download_and_check("${DOUBLE_CONVERSION_URL}" "${DOUBLE_CONVERSION_DOWNLOAD_FILE}" "${DOUBLE_CONVERSION_SHA256}")

thirdparty_extract_and_rename("${DOUBLE_CONVERSION_DOWNLOAD_FILE}" "${DOUBLE_CONVERSION_SOURCE_DIR}" "${THIRDPARTY_SRC_DIR}/double-conversion-*")

# Patch the CMakeLists.txt to use a higher minimum version
file(READ "${DOUBLE_CONVERSION_SOURCE_DIR}/CMakeLists.txt" _cmake_content)
string(REPLACE "cmake_minimum_required(VERSION 3.0)" 
               "cmake_minimum_required(VERSION 3.25)" 
               _cmake_content "${_cmake_content}")
file(WRITE "${DOUBLE_CONVERSION_SOURCE_DIR}/CMakeLists.txt" "${_cmake_content}")

# Configure double-conversion with CMake and optimization flags
thirdparty_get_optimization_flags(_opt_flags)
list(APPEND _opt_flags
    -DCMAKE_INSTALL_PREFIX=${DOUBLE_CONVERSION_INSTALL_DIR}
    -DBUILD_TESTING=OFF
)

thirdparty_cmake_configure("${DOUBLE_CONVERSION_SOURCE_DIR}" "${DOUBLE_CONVERSION_BUILD_DIR}"
    VALIDATION_FILES
        "${DOUBLE_CONVERSION_BUILD_DIR}/CMakeCache.txt"
        "${DOUBLE_CONVERSION_BUILD_DIR}/Makefile"
    ${_opt_flags}
)

# Build and install double-conversion
thirdparty_cmake_install("${DOUBLE_CONVERSION_BUILD_DIR}" "${DOUBLE_CONVERSION_INSTALL_DIR}"
    VALIDATION_FILES
        "${DOUBLE_CONVERSION_INSTALL_DIR}/lib/cmake/double-conversion/double-conversionConfig.cmake"
        "${DOUBLE_CONVERSION_INSTALL_DIR}/lib/libdouble-conversion.a"
        "${DOUBLE_CONVERSION_INSTALL_DIR}/include/double-conversion/double-conversion.h"
)

# Export double-conversion to global scope
if(EXISTS "${DOUBLE_CONVERSION_INSTALL_DIR}/lib/cmake/double-conversion/double-conversionConfig.cmake")
    list(APPEND CMAKE_PREFIX_PATH "${DOUBLE_CONVERSION_INSTALL_DIR}")
    set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" PARENT_SCOPE)
    set(double-conversion_DIR "${DOUBLE_CONVERSION_INSTALL_DIR}/lib/cmake/double-conversion" CACHE PATH "Path to installed double-conversion cmake config" FORCE)
    message(STATUS "double-conversion found and exported globally: ${DOUBLE_CONVERSION_INSTALL_DIR}")
else()
    message(WARNING "double-conversion installation not found at ${DOUBLE_CONVERSION_INSTALL_DIR}")
endif()
