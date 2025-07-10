cmake_minimum_required(VERSION 3.25)
project(halo VERSION 1.0.0 LANGUAGES CXX)

# Set minimum policy version to avoid compatibility issues
cmake_policy(VERSION 3.25)

# C++ standard settings
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Prefer static libraries over shared libraries for better compatibility
# This will prioritize static libraries when both static and shared are available
# and fall back to shared libraries when only shared libraries are available
set(BUILD_SHARED_LIBS OFF)

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

# Include required modules
include(FetchContent)

# Suppress CMake developer warnings (including third-party library warnings)
set(CMAKE_SUPPRESS_DEVELOPER_WARNINGS ON CACHE BOOL "Suppress CMake developer warnings")
set(CMAKE_WARN_DEPRECATED OFF CACHE BOOL "Suppress deprecated warnings")

# Global linker settings: suppress duplicate libraries warning
add_link_options(
    $<$<PLATFORM_ID:Darwin>:-Wl,-no_warn_duplicate_libraries>
    $<$<PLATFORM_ID:Linux>:-Wl,--allow-multiple-definition>
)

# Build order: thirdparty -> src -> test
add_subdirectory(thirdparty)
add_subdirectory(src)
add_subdirectory(test)

# Enable CTest automated testing
include(CTest)
enable_testing()
