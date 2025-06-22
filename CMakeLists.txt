cmake_minimum_required(VERSION 3.24)
project(halo VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Set build type if not specified
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

# Define paths for third-party libraries
set(THIRDPARTY_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty)
set(THIRDPARTY_DOWNLOAD_DIR ${THIRDPARTY_ROOT}/downloads)
set(THIRDPARTY_SRC_DIR ${THIRDPARTY_ROOT}/src)
set(THIRDPARTY_BUILD_DIR ${THIRDPARTY_ROOT}/builds)
set(THIRDPARTY_INSTALL_DIR ${THIRDPARTY_ROOT}/installed)

# Include ExternalProject for managing third-party libraries
include(ExternalProject)
include(FetchContent)

# Include third-party dependencies
add_subdirectory(thirdparty)

# Include the main project source
add_subdirectory(src)

# 启用CTest自动化测试
include(CTest)
enable_testing()

# 设置RPATH，自动查找第三方库
set(CMAKE_SKIP_BUILD_RPATH FALSE)
set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
set(CMAKE_INSTALL_RPATH "${THIRDPARTY_INSTALL_DIR}/lib")
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
