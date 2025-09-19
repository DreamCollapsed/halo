cmake_minimum_required(VERSION 3.25)
project(halo VERSION 1.0.0 LANGUAGES C CXX)

# Set minimum policy version to avoid compatibility issues
cmake_policy(VERSION 3.25)

# C++ standard settings
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

if(APPLE)
    # Auto-detect macOS deployment target with multiple fallback strategies
    set(_macos_target "")
    
    # Priority 1: Use explicitly set CMAKE_OSX_DEPLOYMENT_TARGET from command line or cache
    if(DEFINED CMAKE_OSX_DEPLOYMENT_TARGET AND CMAKE_OSX_DEPLOYMENT_TARGET)
        set(_macos_target "${CMAKE_OSX_DEPLOYMENT_TARGET}")
    else()
        # Priority 2: Auto-detect from system version using sw_vers
        find_program(SW_VERS_EXECUTABLE sw_vers)
        if(SW_VERS_EXECUTABLE)
            execute_process(
                COMMAND ${SW_VERS_EXECUTABLE} -productVersion
                OUTPUT_VARIABLE _system_version
                OUTPUT_STRIP_TRAILING_WHITESPACE
                ERROR_QUIET
            )
            if(_system_version)
                # Extract major.minor version (e.g., "14.5.1" -> "14.5")
                string(REGEX MATCH "^([0-9]+\\.[0-9]+)" _macos_target "${_system_version}")
            endif()
        endif()
        
        # Priority 3: Fallback to CMAKE_HOST_SYSTEM_VERSION if sw_vers failed
        if(NOT _macos_target AND CMAKE_HOST_SYSTEM_VERSION)
            string(REGEX MATCH "^([0-9]+\\.[0-9]+)" _macos_target "${CMAKE_HOST_SYSTEM_VERSION}")
            if(_macos_target)
            endif()
        endif()
    endif()
    message(STATUS "Detected macOS deployment target: ${_macos_target}")
    set(CMAKE_OSX_DEPLOYMENT_TARGET "${_macos_target}" CACHE STRING "macOS deployment target" FORCE)
    add_compile_options(-mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET})
    add_link_options(-mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET})
    
    set(HALO_MACOS_DEPLOYMENT_TARGET "${_macos_target}" CACHE INTERNAL "Detected macOS deployment target for third-party libraries")

    # macOS: ensure system SDK is visible to Homebrew LLVM/clang-scan-deps
    if(NOT DEFINED CMAKE_OSX_SYSROOT OR CMAKE_OSX_SYSROOT STREQUAL "")
      find_program(XCRUN_EXECUTABLE xcrun)
      if(XCRUN_EXECUTABLE)
        execute_process(
          COMMAND "${XCRUN_EXECUTABLE}" --show-sdk-path
          OUTPUT_VARIABLE _HALO_MACOS_SDK
          OUTPUT_STRIP_TRAILING_WHITESPACE
          ERROR_QUIET)
        if(_HALO_MACOS_SDK AND EXISTS "${_HALO_MACOS_SDK}")
          add_compile_options(-isysroot "${_HALO_MACOS_SDK}")
          add_link_options(-isysroot "${_HALO_MACOS_SDK}")
        endif()
      endif()
    endif()
endif()

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
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "Shared Libraries: ${BUILD_SHARED_LIBS}")
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    message(STATUS "Optimization: Maximum (-O3)")
elseif(CMAKE_BUILD_TYPE STREQUAL "Debug")
    message(STATUS "Optimization: None (-O0), Debug symbols enabled")
elseif(CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
    message(STATUS "Optimization: Moderate (-O2), Debug symbols enabled")
elseif(CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
    message(STATUS "Optimization: Size (-Os)")
endif()

include(cmake/modules/FindLinker.cmake)
linker_configure()
linker_add_selfcheck()

option(HALO_FORCE_THIRDPARTY_REINSTALL "Force rebuilding and reinstalling all third-party CMake projects (disables install stamp skipping)" OFF)
option(HALO_THIRDPARTY_VERBOSE_SUPPRESS "Print STATUS messages (instead of DEBUG) when third-party configure/install steps are skipped" ON)

# -----------------------------------------------------------------------------
# Linker switch detection & third-party cache invalidation
# When the accelerated linker selection changes (kind or executable path),
# previously built third-party objects/libraries may embed linker-specific
# metadata or differ in subtle ways (especially with mold/lld vs system ld).
# To avoid hard-to-diagnose inconsistencies we (optionally) wipe the
# thirdparty/builds directory so that all external projects reconfigure
# under the new linker. Installed artifacts are left intact by default to
# minimize rebuild cost; if a full clean is desired the user can remove
# thirdparty/installed manually.
# -----------------------------------------------------------------------------
option(HALO_RESET_THIRDPARTY_ON_LINKER_SWITCH "Automatically remove thirdparty/builds when linker selection changes" ON)

set(_HALO_LINKER_SIGNATURE "${HALO_LINKER_KIND}|${HALO_LINKER_EXECUTABLE}")
get_property(_HALO_PREV_SIG CACHE HALO_PREV_LINKER_SIGNATURE PROPERTY VALUE)
if(NOT _HALO_PREV_SIG)
    # First configure: record signature
    set(HALO_PREV_LINKER_SIGNATURE "${_HALO_LINKER_SIGNATURE}" CACHE INTERNAL "Previous linker signature" FORCE)
else()
    if(NOT _HALO_PREV_SIG STREQUAL _HALO_LINKER_SIGNATURE)
        set(HALO_LINKER_SWITCH_DETECTED TRUE CACHE INTERNAL "Linker switch detected" FORCE)
        message(STATUS "[linker] Switch detected: '${_HALO_PREV_SIG}' -> '${_HALO_LINKER_SIGNATURE}'")
        if(HALO_RESET_THIRDPARTY_ON_LINKER_SWITCH)
            set(_thirdparty_build_dir "${CMAKE_SOURCE_DIR}/thirdparty/builds")
            if(EXISTS "${_thirdparty_build_dir}")
                message(WARNING "[linker] Removing stale third-party build cache: ${_thirdparty_build_dir}")
                file(REMOVE_RECURSE "${_thirdparty_build_dir}")
            endif()
        else()
            message(STATUS "[linker] HALO_RESET_THIRDPARTY_ON_LINKER_SWITCH=OFF; keeping existing third-party build cache (may be inconsistent).")
        endif()
        # Update stored signature after handling switch
        set(HALO_PREV_LINKER_SIGNATURE "${_HALO_LINKER_SIGNATURE}" CACHE INTERNAL "Previous linker signature" FORCE)
    endif()
endif()

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

# Suppress CMake developer warnings (including third-party library warnings)
set(CMAKE_SUPPRESS_DEVELOPER_WARNINGS ON CACHE BOOL "Suppress CMake developer warnings")
set(CMAKE_WARN_DEPRECATED OFF CACHE BOOL "Suppress deprecated warnings")

# Global linker settings: suppress warnings and duplicate libraries
add_link_options(
    $<$<PLATFORM_ID:Darwin>:-Wl,-w>                          # Suppress all linker warnings on macOS
    $<$<PLATFORM_ID:Darwin>:-Wl,-no_warn_duplicate_libraries> # Suppress duplicate library warnings on macOS
    $<$<PLATFORM_ID:Linux>:-Wl,--allow-multiple-definition>  # Allow multiple definitions on Linux
)

set(THIRDPARTY_BASE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty)
set(THIRDPARTY_DOWNLOAD_DIR ${THIRDPARTY_BASE_DIR}/downloads)
set(THIRDPARTY_SRC_DIR ${THIRDPARTY_BASE_DIR}/src)
set(THIRDPARTY_BUILD_DIR ${THIRDPARTY_BASE_DIR}/builds)
set(THIRDPARTY_INSTALL_DIR ${THIRDPARTY_BASE_DIR}/installed)
set(THIRDPARTY_EXECUTABLE_PATHS "" CACHE INTERNAL "Collected third-party executable paths")
add_subdirectory(thirdparty)

message(STATUS "[  Halo Embedded Code  ] Velox integration")
include(cmake/Velox.cmake)
add_subdirectory(velox)

add_subdirectory(src)
add_subdirectory(test)

# Enable CTest automated testing
include(CTest)
enable_testing()
