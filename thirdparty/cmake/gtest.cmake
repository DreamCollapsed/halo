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

find_package(GTest CONFIG REQUIRED)

thirdparty_map_imported_config(
    GTest::gtest
    GTest::gtest_main
    GTest::gmock
    GTest::gmock_main
)
