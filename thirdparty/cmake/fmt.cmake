# fmt third-party integration
# Reference: https://github.com/fmtlib/fmt

# Check dependencies (fmt has no dependencies)
thirdparty_check_dependencies("fmt")

# Set up directories (variables from ComponentsInfo.cmake)
set(FMT_NAME "fmt")
set(FMT_DOWNLOAD_FILE "${THIRDPARTY_DOWNLOAD_DIR}/fmt-${FMT_VERSION}.tar.gz")
set(FMT_SOURCE_DIR "${THIRDPARTY_SRC_DIR}/${FMT_NAME}")
set(FMT_BUILD_DIR "${THIRDPARTY_BUILD_DIR}/${FMT_NAME}")
set(FMT_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/${FMT_NAME}")

# Make sure the installation directory is absolute
get_filename_component(FMT_INSTALL_DIR "${FMT_INSTALL_DIR}" ABSOLUTE)

# Download and extract fmt
thirdparty_download_and_check("${FMT_URL}" "${FMT_DOWNLOAD_FILE}" "${FMT_SHA256}")
thirdparty_extract_and_rename("${FMT_DOWNLOAD_FILE}" "${FMT_SOURCE_DIR}" "${THIRDPARTY_SRC_DIR}/fmt-*")

# Configure fmt with CMake and optimization flags
thirdparty_get_optimization_flags(_opt_flags)
list(APPEND _opt_flags
    -DCMAKE_INSTALL_PREFIX=${FMT_INSTALL_DIR}
    -DFMT_DOC=OFF
    -DFMT_TEST=OFF
    -DFMT_FUZZ=OFF
    -DFMT_CUDA_TEST=OFF
)

thirdparty_cmake_configure("${FMT_SOURCE_DIR}" "${FMT_BUILD_DIR}"
    VALIDATION_FILES
        "${FMT_BUILD_DIR}/CMakeCache.txt"
        "${FMT_BUILD_DIR}/Makefile"
    ${_opt_flags}
)

thirdparty_cmake_install("${FMT_BUILD_DIR}" "${FMT_INSTALL_DIR}"
    VALIDATION_FILES
        "${FMT_INSTALL_DIR}/lib/cmake/fmt/fmt-config.cmake"
        "${FMT_INSTALL_DIR}/lib/libfmt.a"
        "${FMT_INSTALL_DIR}/include/fmt/format.h"
        "${FMT_INSTALL_DIR}/include/fmt/core.h"
)

# Export fmt to global scope
if(EXISTS "${FMT_INSTALL_DIR}/lib/cmake/fmt/fmt-config.cmake")
    list(APPEND CMAKE_PREFIX_PATH "${FMT_INSTALL_DIR}")
    set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" PARENT_SCOPE)
    set(fmt_DIR "${FMT_INSTALL_DIR}/lib/cmake/fmt" CACHE PATH "Path to installed fmt cmake config" FORCE)
    message(STATUS "fmt found and exported globally: ${FMT_INSTALL_DIR}")
else()
    message(WARNING "fmt installation not found at ${FMT_INSTALL_DIR}")
endif()
