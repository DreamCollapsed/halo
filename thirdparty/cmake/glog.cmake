# glog third-party integration
# Reference: https://github.com/google/glog
# Dependencies: gflags, gtest

# Check dependencies using the new dependency management system
thirdparty_check_dependencies("glog")

# Set up directories (variables from ComponentsInfo.cmake)
set(GLOG_NAME "glog")
set(GLOG_DOWNLOAD_FILE "${THIRDPARTY_DOWNLOAD_DIR}/glog-${GLOG_VERSION}.tar.gz")
set(GLOG_SOURCE_DIR "${THIRDPARTY_SRC_DIR}/${GLOG_NAME}")
set(GLOG_BUILD_DIR "${THIRDPARTY_BUILD_DIR}/${GLOG_NAME}")
set(GLOG_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/${GLOG_NAME}")

# Make sure the installation directory is absolute
get_filename_component(GLOG_INSTALL_DIR "${GLOG_INSTALL_DIR}" ABSOLUTE)

# Download and extract glog
thirdparty_download_and_check("${GLOG_URL}" "${GLOG_DOWNLOAD_FILE}" "${GLOG_SHA256}")

thirdparty_extract_and_rename("${GLOG_DOWNLOAD_FILE}" "${GLOG_SOURCE_DIR}" "${THIRDPARTY_SRC_DIR}/glog-*")

# Configure glog with dependencies and optimization flags
thirdparty_get_optimization_flags(_opt_flags COMPONENT glog)

list(APPEND _opt_flags
    -DCMAKE_INSTALL_PREFIX=${GLOG_INSTALL_DIR}
    -DWITH_GFLAGS=ON
    -DWITH_GTEST=ON
    -DWITH_GMOCK=ON
    -DGFLAGS_USE_TARGET_NAMESPACE=TRUE
)

thirdparty_cmake_configure("${GLOG_SOURCE_DIR}" "${GLOG_BUILD_DIR}"
    VALIDATION_FILES
        "${GLOG_BUILD_DIR}/CMakeCache.txt"
        "${GLOG_BUILD_DIR}/Makefile"
    CMAKE_ARGS
        ${_opt_flags}
)

# Build and install glog
thirdparty_cmake_install("${GLOG_BUILD_DIR}" "${GLOG_INSTALL_DIR}"
    VALIDATION_FILES
        "${GLOG_INSTALL_DIR}/lib/cmake/glog/glog-config.cmake"
        "${GLOG_INSTALL_DIR}/lib/libglog.a"
        "${GLOG_INSTALL_DIR}/include/glog/logging.h"
        "${GLOG_INSTALL_DIR}/include/glog/log_severity.h"
)

# Export glog to global scope
if(EXISTS "${GLOG_INSTALL_DIR}/lib/cmake/glog/glog-config.cmake")
    list(APPEND CMAKE_PREFIX_PATH "${GLOG_INSTALL_DIR}")
    set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" PARENT_SCOPE)
    set(glog_DIR "${GLOG_INSTALL_DIR}/lib/cmake/glog" CACHE PATH "Path to installed glog cmake config" FORCE)
    message(STATUS "glog found and exported globally: ${GLOG_INSTALL_DIR}")
else()
    message(WARNING "glog installation not found at ${GLOG_INSTALL_DIR}")
endif()
