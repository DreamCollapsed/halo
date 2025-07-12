# GoogleTest third-party integration
# Reference: https://google.github.io/googletest/quickstart-cmake.html

# Check dependencies (gtest has no dependencies)
thirdparty_check_dependencies("gtest")

# Set up directories (variables from ComponentsInfo.cmake)
set(GTEST_NAME "gtest")
set(GTEST_DOWNLOAD_FILE "${THIRDPARTY_DOWNLOAD_DIR}/googletest-${GOOGLETEST_VERSION}.tar.gz")
set(GTEST_SOURCE_DIR "${THIRDPARTY_SRC_DIR}/${GTEST_NAME}")
set(GTEST_BUILD_DIR "${THIRDPARTY_BUILD_DIR}/${GTEST_NAME}")
set(GTEST_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/${GTEST_NAME}")

# Make sure the installation directory is absolute
get_filename_component(GTEST_INSTALL_DIR "${GTEST_INSTALL_DIR}" ABSOLUTE)

# Download and extract GoogleTest
thirdparty_download_and_check("${GOOGLETEST_URL}" "${GTEST_DOWNLOAD_FILE}" "${GOOGLETEST_SHA256}")
thirdparty_extract_and_rename("${GTEST_DOWNLOAD_FILE}" "${GTEST_SOURCE_DIR}" "${THIRDPARTY_SRC_DIR}/googletest-*")

# Configure GoogleTest with modern CMake approach and optimization flags
thirdparty_get_optimization_flags(_opt_flags)
list(APPEND _opt_flags
    -DCMAKE_INSTALL_PREFIX=${GTEST_INSTALL_DIR}
    -DINSTALL_GTEST=ON
    -DBUILD_GMOCK=ON
)

# Use both exact file validation and pattern matching to ensure all key files exist
thirdparty_cmake_configure("${GTEST_SOURCE_DIR}" "${GTEST_BUILD_DIR}"
    VALIDATION_FILES
      "${GTEST_BUILD_DIR}/CMakeCache.txt"
      "${GTEST_BUILD_DIR}/Makefile"
    CMAKE_ARGS
        ${_opt_flags}
)

# Build and install (only when key files don't exist)
thirdparty_cmake_install("${GTEST_BUILD_DIR}" "${GTEST_INSTALL_DIR}"
    VALIDATION_FILES
        "${GTEST_INSTALL_DIR}/lib/cmake/GTest/GTestConfig.cmake"
        "${GTEST_INSTALL_DIR}/lib/libgtest.a"
        "${GTEST_INSTALL_DIR}/lib/libgtest_main.a"
        "${GTEST_INSTALL_DIR}/lib/libgmock.a"
        "${GTEST_INSTALL_DIR}/lib/libgmock_main.a"
        "${GTEST_INSTALL_DIR}/include/gtest/gtest.h"
        "${GTEST_INSTALL_DIR}/include/gmock/gmock.h"
)

# Export GTest to parent scope
if(EXISTS "${GTEST_INSTALL_DIR}/lib/cmake/GTest/GTestConfig.cmake")
    list(APPEND CMAKE_PREFIX_PATH "${GTEST_INSTALL_DIR}")
    set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" PARENT_SCOPE)
    set(GTest_DIR "${GTEST_INSTALL_DIR}/lib/cmake/GTest" CACHE PATH "Path to installed GTest cmake config" FORCE)
    message(STATUS "GTest/GMock found and exported globally: ${GTEST_INSTALL_DIR}")
else()
    message(WARNING "GTest installation not found at ${GTEST_INSTALL_DIR}")
endif()
