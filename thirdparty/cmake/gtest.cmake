# GoogleTest/GoogleMock third-party integration
# Reference: https://google.github.io/googletest/quickstart-cmake.html

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

set(GTEST_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/gtest")
get_filename_component(GTEST_INSTALL_DIR "${GTEST_INSTALL_DIR}" ABSOLUTE)

if(EXISTS "${GTEST_INSTALL_DIR}/lib/cmake/GTest/GTestConfig.cmake")
    find_package(GTest CONFIG REQUIRED)
    
    message(STATUS "GTest/GMock found and exported globally: ${GTEST_INSTALL_DIR}")
else()
    message(FATAL_ERROR "GTest installation not found at ${GTEST_INSTALL_DIR}")
endif()