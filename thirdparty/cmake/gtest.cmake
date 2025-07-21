# GoogleTest/GoogleMock third-party integration
# Reference: https://google.github.io/googletest/quickstart-cmake.html

# Map GOOGLETEST_* variables to GTEST_* for standardized function
set(GTEST_VERSION "${GOOGLETEST_VERSION}")
set(GTEST_URL "${GOOGLETEST_URL}")
set(GTEST_SHA256 "${GOOGLETEST_SHA256}")

# Use the standardized build function for GoogleTest
thirdparty_build_cmake_library("gtest"
    EXTRACT_PATTERN "${THIRDPARTY_SRC_DIR}/googletest-*"
    CMAKE_ARGS
        -DBUILD_GMOCK=ON
        -DBUILD_GTEST=ON
        -DGTEST_CREATE_SHARED_LIBRARY=OFF
        -DGTEST_FORCE_SHARED_CRT=OFF
        -DINSTALL_GTEST=ON
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/gtest/lib/cmake/GTest/GTestConfig.cmake"
        "${THIRDPARTY_INSTALL_DIR}/gtest/lib/libgtest.a"
        "${THIRDPARTY_INSTALL_DIR}/gtest/lib/libgmock.a"
        "${THIRDPARTY_INSTALL_DIR}/gtest/include/gtest/gtest.h"
        "${THIRDPARTY_INSTALL_DIR}/gtest/include/gmock/gmock.h"
)

# Additional gtest-specific setup
set(GTEST_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/gtest")
get_filename_component(GTEST_INSTALL_DIR "${GTEST_INSTALL_DIR}" ABSOLUTE)

if(EXISTS "${GTEST_INSTALL_DIR}/lib/cmake/GTest/GTestConfig.cmake")
    set(GTest_DIR "${GTEST_INSTALL_DIR}/lib/cmake/GTest" CACHE PATH "Path to installed GTest cmake config" FORCE)
    
    # Import GTest package immediately
    find_package(GTest REQUIRED CONFIG QUIET)
    
    message(STATUS "GTest/GMock found and exported globally: ${GTEST_INSTALL_DIR}")
else()
    message(WARNING "GTest installation not found at ${GTEST_INSTALL_DIR}")
endif()