cmake_minimum_required(VERSION 3.30)
project(halo VERSION 1.0.0 LANGUAGES C CXX)

cmake_policy(VERSION 3.30)

# C++ standard settings
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

if(NOT CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
  message(FATAL_ERROR "This project requires Clang compiler. Current compiler: ${CMAKE_CXX_COMPILER_ID}")
endif()

# Enable Split DWARF for Debug builds to reduce link time and memory usage
# Only supported on Linux with Clang/GCC. macOS uses dSYM bundles.
if((CMAKE_BUILD_TYPE STREQUAL "Debug" OR CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo") AND CMAKE_SYSTEM_NAME STREQUAL "Linux")
  add_compile_options(-gsplit-dwarf)
  add_link_options(-gsplit-dwarf)
  message(STATUS "Enabled Split DWARF (-gsplit-dwarf) for faster linking")
endif()

# On Linux, when using Clang with libstdc++ (GCC's standard library),
# we must prevent Clang from including its own libc++ headers which conflict with libstdc++.
# We need to properly configure --gcc-toolchain to point to the actual GCC installation.
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
  set(_gcc_toolchain_candidates "/usr" "/usr/local")
  set(_gcc_toolchain_root "")

  # Look for include/c++/* directories
  foreach(_candidate ${_gcc_toolchain_candidates})
    if(EXISTS "${_candidate}/include/c++")
      file(GLOB _cxx_versions "${_candidate}/include/c++/*")
      list(LENGTH _cxx_versions _num_versions)

      if(_num_versions GREATER 0)
        set(_gcc_toolchain_root "${_candidate}")
        message(STATUS "Found GCC C++ headers in: ${_candidate}/include/c++")
        break()
      endif()
    endif()
  endforeach()

  # If not found in standard locations, try to detect from g++
  if(NOT _gcc_toolchain_root)
    find_program(GXX_EXECUTABLE g++)

    if(GXX_EXECUTABLE)
      # Ask g++ where its installation is
      execute_process(
        COMMAND ${GXX_EXECUTABLE} -print-file-name=include
        OUTPUT_VARIABLE _gxx_include_dir
        OUTPUT_STRIP_TRAILING_WHITESPACE
      )

      if(_gxx_include_dir AND EXISTS "${_gxx_include_dir}")
        # _gxx_include_dir is usually something like /usr/lib/gcc/x86_64-linux-gnu/14/include
        # We need to go up to /usr
        if(_gxx_include_dir MATCHES "^(/usr)/")
          set(_gcc_toolchain_root "/usr")
        endif()
      endif()
    endif()
  endif()

  # Simple configuration: rely on Clang toolchain detection + libstdc++.
  if(_gcc_toolchain_root)
    add_compile_options(-stdlib=libstdc++ "--gcc-toolchain=${_gcc_toolchain_root}")
    add_link_options(-stdlib=libstdc++ "--gcc-toolchain=${_gcc_toolchain_root}")

    if(CMAKE_CXX_FLAGS)
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libstdc++ --gcc-toolchain=${_gcc_toolchain_root}" CACHE STRING "C++ flags" FORCE)
    else()
      set(CMAKE_CXX_FLAGS "-stdlib=libstdc++ --gcc-toolchain=${_gcc_toolchain_root}" CACHE STRING "C++ flags" FORCE)
    endif()

    message(STATUS "[libstdc++] Using GCC toolchain root='${_gcc_toolchain_root}' (default Clang search paths)")

    message(STATUS "[libstdc++] Detected libstdc++; GNU extension warnings will be suppressed in centralized block")
  endif()
endif()

get_filename_component(COMPILER_BIN_DIR "${CMAKE_CXX_COMPILER}" DIRECTORY)
get_filename_component(COMPILER_ROOT "${COMPILER_BIN_DIR}/.." ABSOLUTE)

# ----------------------------------------------------------------------------
# High-performance instruction set auto-selection (Linux x86_64 only)
# ----------------------------------------------------------------------------
# Simple, non-configurable: detect highest available feature level and apply
# a matching -march (v4 -> avx512f, v3 -> avx2, v2 -> sse4.2). If none found,
# do nothing (portable fallback). This avoids maintenance of multiple cache
# options while ensuring consistency across main and third-party builds.
# ----------------------------------------------------------------------------
set(HALO_LINUX_X86_64_MARCH_VERSION_RESTRICT "v4" CACHE STRING "Restrict maximum march version for Linux x86_64")
set_property(CACHE HALO_LINUX_X86_64_MARCH_VERSION_RESTRICT PROPERTY STRINGS v4 v3 v2 none)

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
  if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64")
    set(_halo_arch_flag "")

    if(EXISTS "/proc/cpuinfo")
      file(READ "/proc/cpuinfo" _halo_cpuinfo)
      string(FIND "${_halo_cpuinfo}" "avx512f" _has_avx512f)
      string(FIND "${_halo_cpuinfo}" "avx2" _has_avx2)
      string(FIND "${_halo_cpuinfo}" "sse4_2" _has_sse42)

      if(_has_avx512f GREATER -1
          AND HALO_LINUX_X86_64_MARCH_VERSION_RESTRICT STREQUAL "v4")
        set(_halo_arch_flag "-march=x86-64-v4")
        set(_halo_arch_level v4)
      elseif(_has_avx2 GREATER -1
              AND (HALO_LINUX_X86_64_MARCH_VERSION_RESTRICT STREQUAL "v4"
                   OR HALO_LINUX_X86_64_MARCH_VERSION_RESTRICT STREQUAL "v3"))
        set(_halo_arch_flag "-march=x86-64-v3")
        set(_halo_arch_level v3)
      elseif(_has_sse42 GREATER -1
              AND (HALO_LINUX_X86_64_MARCH_VERSION_RESTRICT STREQUAL "v4"
                   OR HALO_LINUX_X86_64_MARCH_VERSION_RESTRICT STREQUAL "v3"
                   OR HALO_LINUX_X86_64_MARCH_VERSION_RESTRICT STREQUAL "v2"))
        set(_halo_arch_flag "-march=x86-64-v2")
        set(_halo_arch_level v2)
      else()
        set(_halo_arch_level none)
      endif()

      message(STATUS "[cpu] Linux x86_64 auto-detect level='${_halo_arch_level}' flags='${_halo_arch_flag}'")

      # Check if AVX512 is available but restricted
      if(_has_avx512f GREATER -1 AND NOT _halo_arch_level STREQUAL "v4" AND NOT HALO_LINUX_X86_64_MARCH_VERSION_RESTRICT STREQUAL "v4")
        message(STATUS "[cpu] AVX512F detected but restricted to '${HALO_LINUX_X86_64_MARCH_VERSION_RESTRICT}'; using '${_halo_arch_level}'")
      endif()
    else()
      message(WARNING "[cpu] /proc/cpuinfo not readable; skipping arch flag (portable fallback)")
    endif()

    if(_halo_arch_flag)
      foreach(_lang_flags_var CMAKE_C_FLAGS CMAKE_CXX_FLAGS)
        if(DEFINED ${_lang_flags_var} AND NOT ${_lang_flags_var} STREQUAL "")
          set(${_lang_flags_var} "${${_lang_flags_var}} ${_halo_arch_flag}" CACHE STRING "${_lang_flags_var}" FORCE)
        else()
          set(${_lang_flags_var} "${_halo_arch_flag}" CACHE STRING "${_lang_flags_var}" FORCE)
        endif()
      endforeach()

      set(HALO_CPU_FEATURE_FLAGS "${_halo_arch_flag}" CACHE INTERNAL "Unified CPU feature flags")
    endif()
  endif()
endif()

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
        set(CMAKE_OSX_SYSROOT "${_HALO_MACOS_SDK}" CACHE PATH "macOS Sysroot" FORCE)
      endif()
    endif()
  endif()

  # Force usage of system C++ headers when using Homebrew LLVM to avoid ABI mismatch with system libc++
  if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang" AND CMAKE_OSX_SYSROOT)
     set(_sys_cxx_headers "${CMAKE_OSX_SYSROOT}/usr/include/c++/v1")
     if(EXISTS "${_sys_cxx_headers}")
       message(STATUS "Forcing system C++ headers from SDK: ${_sys_cxx_headers}")
       # We must modify CMAKE_CXX_FLAGS so it propagates to third-party builds via ThirdpartyUtils
       # Check if already present to avoid duplication
       string(FIND "${CMAKE_CXX_FLAGS}" "-nostdinc++" _has_nostdinc)
       if(_has_nostdinc EQUAL -1)
         set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -nostdinc++ -I${_sys_cxx_headers}" CACHE STRING "Flags used by the CXX compiler" FORCE)
       endif()
     endif()
  endif()

  add_compile_options(
    $<$<CONFIG:Debug>:-Wno-gnu-zero-variadic-macro-arguments>
    $<$<CONFIG:Debug>:-Wno-gnu-statement-expression>
  )
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

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
  find_program(PKG_CONFIG_EXECUTABLE NAMES pkgconf pkg-config)

  if(NOT PKG_CONFIG_EXECUTABLE)
    message(WARNING "Neither pkgconf nor pkg-config found. Some dependencies may not be detected correctly.")
  else()
    message(STATUS "Using pkg-config executable: ${PKG_CONFIG_EXECUTABLE}")
  endif()
else()
  message(STATUS "Apple platform detected, skipping pkg-config search.")
endif()

# -----------------------------------------------------------------------------
# Compiler feature / warning flag probes (performed once)
# -----------------------------------------------------------------------------
include(CheckCXXCompilerFlag)
check_cxx_compiler_flag("-Wno-sign-compare" COMPILER_SUPPORTS_WNO_SIGN_COMPARE)
check_cxx_compiler_flag("-Wno-extra-semi" COMPILER_SUPPORTS_WNO_EXTRA_SEMI)

# ##############################################################################
# LTO mode selection
# HALO_LTO_MODE: full | thin | off  (default full for optimized builds)
# Applies to root targets; third-party propagation handled in ThirdpartyUtils.
# ##############################################################################
set(HALO_LTO_MODE "full" CACHE STRING "LTO mode (full|thin|off)")
set_property(CACHE HALO_LTO_MODE PROPERTY STRINGS full thin off)

if(CMAKE_BUILD_TYPE MATCHES "^Release$" OR CMAKE_BUILD_TYPE MATCHES "^RelWithDebInfo$")
  if(NOT HALO_LTO_MODE STREQUAL "off")
    include(CheckIPOSupported)
    check_ipo_supported(RESULT _ipo_supported OUTPUT _ipo_msg)

    if(_ipo_supported)
      # Override CMake's default IPO flags BEFORE enabling CMAKE_INTERPROCEDURAL_OPTIMIZATION
      # to prevent automatic -flto=thin on macOS+Clang which would conflict with our explicit flags
      if(HALO_LTO_MODE STREQUAL "thin")
        set(CMAKE_CXX_COMPILE_OPTIONS_IPO "-flto=thin")
        set(CMAKE_C_COMPILE_OPTIONS_IPO "-flto=thin")
        set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)
        message(DEBUG "[LTO] ThinLTO enabled for ${CMAKE_BUILD_TYPE}")
      elseif(HALO_LTO_MODE STREQUAL "full")
        # Explicit full LTO, override CMake defaults
        set(CMAKE_CXX_COMPILE_OPTIONS_IPO "-flto")
        set(CMAKE_C_COMPILE_OPTIONS_IPO "-flto")
        set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)
        message(STATUS "[LTO] Full LTO enabled for ${CMAKE_BUILD_TYPE}")
      else()
        message(WARNING "[LTO] Unknown HALO_LTO_MODE='${HALO_LTO_MODE}', falling back to full")
        set(CMAKE_CXX_COMPILE_OPTIONS_IPO "-flto")
        set(CMAKE_C_COMPILE_OPTIONS_IPO "-flto")
        set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)
      endif()
    else()
      message(STATUS "[LTO] Not supported by toolchain: ${_ipo_msg}")
    endif()
  else()
    message(STATUS "[LTO] Disabled via HALO_LTO_MODE=off")
  endif()
else()
  message(STATUS "[LTO] Skipped for non-optimized build type ${CMAKE_BUILD_TYPE}")
endif()

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
  # Add extra debug flags for better debugging experience (Clang only)
  add_compile_options(
    -Wall # Enable most warnings
    -Wextra # Enable extra warnings
    -Wpedantic # Enable pedantic warnings
    -Wno-unused-parameter # Suppress unused parameter warnings
    -fno-omit-frame-pointer # Keep frame pointers for better stack traces
    -fno-optimize-sibling-calls # Better debugging experience
  )

  if(COMPILER_SUPPORTS_WNO_SIGN_COMPARE)
    add_compile_options(-Wno-sign-compare)
  endif()

  if(COMPILER_SUPPORTS_WNO_EXTRA_SEMI)
    add_compile_options(-Wno-extra-semi)
  endif()
elseif(CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
  # RelWithDebInfo: Optimized with debug symbols for profiling (Clang only)
  # Probe support for -fno-inline-small-functions (not all clang builds enable it)
  check_cxx_compiler_flag("-fno-inline-small-functions" COMPILER_SUPPORTS_FNO_INLINE_SMALL_FUNCTIONS)

  if(COMPILER_SUPPORTS_FNO_INLINE_SMALL_FUNCTIONS)
    add_compile_options(
      -fno-omit-frame-pointer # Keep frame pointers for profiling
      -fno-inline-small-functions # Better profiling granularity
    )
  else()
    add_compile_options(
      -fno-omit-frame-pointer # Keep frame pointers for profiling
    )
    message(STATUS "[profiling] Compiler does not support -fno-inline-small-functions; skipping flag")
  endif()

  # Enable some debug definitions but not heavy runtime checks
  add_compile_definitions(
    ENABLE_PROFILING # Custom profiling hooks
    DEBUG_SYMBOLS_ENABLED # Indicate debug symbols are available
  )
elseif(CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
  # MinSizeRel: Focus on minimal binary size (Clang only)
  add_compile_options(
    -ffunction-sections # Place functions in separate sections
    -fdata-sections # Place data in separate sections
  )

  # Platform-specific linker flags for dead code removal
  if(APPLE)
    add_link_options(-Wl,-dead_strip) # Remove unused sections (macOS)
  else()
    add_link_options(-Wl,--gc-sections) # Remove unused sections (Linux/GNU)
  endif()

  # Size optimization definitions
  add_compile_definitions(
    MINIMAL_BUILD # Disable optional features
    NO_DEBUG_OUTPUT # Remove debug output
  )
endif()

# Suppress CMake developer warnings (including third-party library warnings)
set(CMAKE_SUPPRESS_DEVELOPER_WARNINGS ON CACHE BOOL "Suppress CMake developer warnings")
set(CMAKE_WARN_DEPRECATED OFF CACHE BOOL "Suppress deprecated warnings")

# Global linker settings: suppress warnings and duplicate libraries
add_link_options(
  $<$<PLATFORM_ID:Darwin>:-Wl,-w> # Suppress all linker warnings on macOS
  $<$<PLATFORM_ID:Darwin>:-Wl,-no_warn_duplicate_libraries> # Suppress duplicate library warnings on macOS
  $<$<PLATFORM_ID:Linux>:-Wl,--allow-multiple-definition> # Allow multiple definitions on Linux
)

set(THIRDPARTY_BASE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty)
set(THIRDPARTY_DOWNLOAD_DIR ${THIRDPARTY_BASE_DIR}/downloads)
set(THIRDPARTY_SRC_DIR ${THIRDPARTY_BASE_DIR}/src)
set(THIRDPARTY_BUILD_DIR ${THIRDPARTY_BASE_DIR}/builds)
set(THIRDPARTY_INSTALL_DIR ${THIRDPARTY_BASE_DIR}/installed)
set(THIRDPARTY_EXECUTABLE_PATHS "" CACHE INTERNAL "Collected third-party executable paths")
add_subdirectory(thirdparty)

message(STATUS "[  Halo Embedded Code  ] DuckDB integration")
include(cmake/DuckDB.cmake)
add_subdirectory(duckdb)

message(STATUS "[  Halo Embedded Code  ] Velox integration")
include(cmake/Velox.cmake)
add_subdirectory(velox)

add_subdirectory(src)
add_subdirectory(test)

# Enable CTest automated testing
include(CTest)
enable_testing()
