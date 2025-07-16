cmake_minimum_required(VERSION 3.25)
project(halo VERSION 1.0.0 LANGUAGES CXX)

# Set minimum policy version to avoid compatibility issues
cmake_policy(VERSION 3.25)

# C++ standard settings
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Force static libraries for the entire project and all third-party libraries
# This CACHE FORCE ensures all subprojects use static libraries
set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build shared libraries" FORCE)

# Set default build type to Release for optimal performance
# But allow override for development and debugging
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build" FORCE)
    # Set the possible values of build type for cmake-gui
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

# Configure build type specific flags
# Release: Maximum optimization for production
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG" CACHE STRING "Flags used by the CXX compiler during Release builds" FORCE)

# Debug: Full debug information, no optimization, enable assertions
set(CMAKE_CXX_FLAGS_DEBUG "-g -O0 -DDEBUG -D_DEBUG" CACHE STRING "Flags used by the CXX compiler during Debug builds" FORCE)

# RelWithDebInfo: Optimized with debug info for profiling
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-O2 -g -DNDEBUG" CACHE STRING "Flags used by the CXX compiler during RelWithDebInfo builds" FORCE)

# MinSizeRel: Optimized for size
set(CMAKE_CXX_FLAGS_MINSIZEREL "-Os -DNDEBUG" CACHE STRING "Flags used by the CXX compiler during MinSizeRel builds" FORCE)

# Display current build configuration
message(STATUS "=== Build Configuration ===")
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "Static Libraries: ${BUILD_SHARED_LIBS}")
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    message(STATUS "Optimization: Maximum (-O3)")
elseif(CMAKE_BUILD_TYPE STREQUAL "Debug")
    message(STATUS "Optimization: None (-O0), Debug symbols enabled")
elseif(CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
    message(STATUS "Optimization: Moderate (-O2), Debug symbols enabled")
elseif(CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
    message(STATUS "Optimization: Size (-Os)")
endif()
message(STATUS "============================")

# Add debug-specific compiler flags for better debugging experience
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    # Add extra debug flags for better debugging experience
    if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        add_compile_options(
            -Wall                    # Enable most warnings
            -Wextra                  # Enable extra warnings
            -Wpedantic               # Enable pedantic warnings
            -Wno-unused-parameter    # Suppress unused parameter warnings
            -fno-omit-frame-pointer  # Keep frame pointers for better stack traces
            -fno-optimize-sibling-calls  # Better debugging experience
        )
    endif()
    
    # Enable runtime checks in debug mode
    add_compile_definitions(
        _GLIBCXX_DEBUG          # Enable libstdc++ debug mode
        _GLIBCXX_DEBUG_PEDANTIC # Enable pedantic debug checks
    )
elseif(CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
    # RelWithDebInfo: Optimized with debug symbols for profiling
    if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        add_compile_options(
            -fno-omit-frame-pointer  # Keep frame pointers for profiling
            -fno-inline-small-functions  # Better profiling granularity
        )
    endif()
    
    # Enable some debug definitions but not heavy runtime checks
    add_compile_definitions(
        ENABLE_PROFILING         # Custom profiling hooks
        DEBUG_SYMBOLS_ENABLED    # Indicate debug symbols are available
    )
elseif(CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
    # MinSizeRel: Focus on minimal binary size
    if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        add_compile_options(
            -ffunction-sections     # Place functions in separate sections
            -fdata-sections         # Place data in separate sections
        )
        # Platform-specific linker flags for dead code removal
        if(APPLE)
            add_link_options(-Wl,-dead_strip)  # Remove unused sections (macOS)
        else()
            add_link_options(-Wl,--gc-sections)  # Remove unused sections (Linux/GNU)
        endif()
    endif()
    
    # Size optimization definitions
    add_compile_definitions(
        MINIMAL_BUILD           # Disable optional features
        NO_DEBUG_OUTPUT         # Remove debug output
    )
endif()

# Define paths for third-party libraries
set(THIRDPARTY_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty)
set(THIRDPARTY_DOWNLOAD_DIR ${THIRDPARTY_ROOT}/downloads)
set(THIRDPARTY_SRC_DIR ${THIRDPARTY_ROOT}/src)
set(THIRDPARTY_BUILD_DIR ${THIRDPARTY_ROOT}/builds)
set(THIRDPARTY_INSTALL_DIR ${THIRDPARTY_ROOT}/installed)

# Suppress CMake developer warnings (including third-party library warnings)
set(CMAKE_SUPPRESS_DEVELOPER_WARNINGS ON CACHE BOOL "Suppress CMake developer warnings")
set(CMAKE_WARN_DEPRECATED OFF CACHE BOOL "Suppress deprecated warnings")

# Global linker settings: suppress warnings and duplicate libraries
add_link_options(
    $<$<PLATFORM_ID:Darwin>:-Wl,-w>                          # Suppress all linker warnings on macOS
    $<$<PLATFORM_ID:Darwin>:-Wl,-no_warn_duplicate_libraries> # Suppress duplicate library warnings on macOS
    $<$<PLATFORM_ID:Linux>:-Wl,--allow-multiple-definition>  # Allow multiple definitions on Linux
)

# Build order: thirdparty -> src -> test
add_subdirectory(thirdparty)

# Link Folly to main project targets
if(TARGET folly)
    # Get all executable and library targets in src/ directory
    get_property(_all_targets DIRECTORY src PROPERTY BUILDSYSTEM_TARGETS)
    
    # Link Folly to all targets except thirdparty_test
    foreach(_target IN LISTS _all_targets)
        if(NOT "${_target}" STREQUAL "thirdparty_test")
            target_link_libraries(${_target} PRIVATE folly)
            message(STATUS "Linking Folly to target: ${_target}")
        endif()
    endforeach()
endif()

add_subdirectory(src)
add_subdirectory(test)

# Enable CTest automated testing
include(CTest)
enable_testing()
