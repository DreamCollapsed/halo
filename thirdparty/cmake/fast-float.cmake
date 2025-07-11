# fast-float third-party integration
# Reference: https://github.com/fastfloat/fast_float

# Check dependencies (fast-float has no dependencies)
thirdparty_check_dependencies("fast-float")

# Set up directories (variables from ComponentsInfo.cmake)
set(FAST_FLOAT_NAME "fast-float")
set(FAST_FLOAT_DOWNLOAD_FILE "${THIRDPARTY_DOWNLOAD_DIR}/fast-float-${FAST_FLOAT_VERSION}.tar.gz")
set(FAST_FLOAT_SOURCE_DIR "${THIRDPARTY_SRC_DIR}/${FAST_FLOAT_NAME}")
set(FAST_FLOAT_BUILD_DIR "${THIRDPARTY_BUILD_DIR}/${FAST_FLOAT_NAME}")
set(FAST_FLOAT_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/${FAST_FLOAT_NAME}")

# Make sure the installation directory is absolute
get_filename_component(FAST_FLOAT_INSTALL_DIR "${FAST_FLOAT_INSTALL_DIR}" ABSOLUTE)

# Download and extract fast-float
thirdparty_download_and_check("${FAST_FLOAT_URL}" "${FAST_FLOAT_DOWNLOAD_FILE}" "${FAST_FLOAT_SHA256}")

thirdparty_extract_and_rename("${FAST_FLOAT_DOWNLOAD_FILE}" "${FAST_FLOAT_SOURCE_DIR}" "${THIRDPARTY_SRC_DIR}/fast_float-*")

# Configure fast-float with CMake and optimization flags
thirdparty_get_optimization_flags(_opt_flags)
list(APPEND _opt_flags
    -DCMAKE_INSTALL_PREFIX=${FAST_FLOAT_INSTALL_DIR}
    -DFASTFLOAT_TEST=OFF
    -DFASTFLOAT_SANITIZE=OFF
)

thirdparty_cmake_configure("${FAST_FLOAT_SOURCE_DIR}" "${FAST_FLOAT_BUILD_DIR}"
    VALIDATION_FILES
        "${FAST_FLOAT_BUILD_DIR}/CMakeCache.txt"
        "${FAST_FLOAT_BUILD_DIR}/Makefile"
    ${_opt_flags}
)

# Build and install fast-float
thirdparty_cmake_install("${FAST_FLOAT_BUILD_DIR}" "${FAST_FLOAT_INSTALL_DIR}"
    VALIDATION_FILES
        "${FAST_FLOAT_INSTALL_DIR}/share/cmake/FastFloat/FastFloatConfig.cmake"
        "${FAST_FLOAT_INSTALL_DIR}/include/fast_float/fast_float.h"
)

# Export fast-float to global scope
if(EXISTS "${FAST_FLOAT_INSTALL_DIR}/share/cmake/FastFloat/FastFloatConfig.cmake")
    list(APPEND CMAKE_PREFIX_PATH "${FAST_FLOAT_INSTALL_DIR}")
    set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" PARENT_SCOPE)
    set(FastFloat_DIR "${FAST_FLOAT_INSTALL_DIR}/share/cmake/FastFloat" CACHE PATH "Path to installed fast-float cmake config" FORCE)
    message(STATUS "fast-float found and exported globally: ${FAST_FLOAT_INSTALL_DIR}")
else()
    message(WARNING "fast-float installation not found at ${FAST_FLOAT_INSTALL_DIR}")
endif()
