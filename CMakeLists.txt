cmake_minimum_required(VERSION 3.25)
project(halo VERSION 1.0.0 LANGUAGES C CXX)

# Set minimum policy version to avoid compatibility issues
cmake_policy(VERSION 3.25)

# C++ standard settings
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Compiler requirements and standard library configuration
if(NOT CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    message(FATAL_ERROR "This project requires Clang compiler. Current compiler: ${CMAKE_CXX_COMPILER_ID}")
endif()

# Detect compiler's associated libc++ paths to ensure version consistency
get_filename_component(COMPILER_BIN_DIR "${CMAKE_CXX_COMPILER}" DIRECTORY)
get_filename_component(COMPILER_ROOT "${COMPILER_BIN_DIR}/.." ABSOLUTE)

#######################################################################
# libc++ discovery (Linux CI may install clang but not ship headers in expected spots)
# Priority order:
#  1. User-provided overrides (LIBCPP_INCLUDE_DIR / LIBCPP_LIB_DIR cache or env)
#  2. Explicit environment variables LIBCXX_INCLUDE / LIBCXX_LIB
#  3. Compiler resource dir probing: clang -print-resource-dir + ../../../include/c++/v1
#  4. Relative to compiler root (legacy layout)
#  5. llvm-config (if available) parent paths
#######################################################################
set(LIBCPP_INCLUDE_DIR "${LIBCPP_INCLUDE_DIR}")
set(LIBCPP_LIB_DIR "${LIBCPP_LIB_DIR}")

# Environment override
if(NOT LIBCPP_INCLUDE_DIR AND DEFINED ENV{LIBCXX_INCLUDE})
    set(LIBCPP_INCLUDE_DIR "$ENV{LIBCXX_INCLUDE}")
endif()
if(NOT LIBCPP_LIB_DIR AND DEFINED ENV{LIBCXX_LIB})
    set(LIBCPP_LIB_DIR "$ENV{LIBCXX_LIB}")
endif()

# Normalize empties to blank
if(LIBCPP_INCLUDE_DIR AND NOT EXISTS "${LIBCPP_INCLUDE_DIR}")
    message(WARNING "Provided LIBCPP_INCLUDE_DIR='${LIBCPP_INCLUDE_DIR}' does not exist; ignoring")
    set(LIBCPP_INCLUDE_DIR "")
endif()
if(LIBCPP_LIB_DIR AND NOT EXISTS "${LIBCPP_LIB_DIR}")
    message(WARNING "Provided LIBCPP_LIB_DIR='${LIBCPP_LIB_DIR}' does not exist; ignoring")
    set(LIBCPP_LIB_DIR "")
endif()

# 3. Resource dir probing
if(NOT LIBCPP_INCLUDE_DIR)
    execute_process(COMMAND ${CMAKE_CXX_COMPILER} -print-resource-dir
                    OUTPUT_VARIABLE _clang_resdir OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
    if(_clang_resdir AND EXISTS "${_clang_resdir}")
        # Typical: <resdir>/../../include/c++/v1
        get_filename_component(_rd_parent "${_clang_resdir}/../.." ABSOLUTE)
        set(_candidate_inc "${_rd_parent}/include/c++/v1")
        if(EXISTS "${_candidate_inc}" AND IS_DIRECTORY "${_candidate_inc}")
            set(LIBCPP_INCLUDE_DIR "${_candidate_inc}")
        endif()
        # Also consider Debian style: /usr/include/c++/v1 already in system include paths, so no-op
    endif()
endif()

# 4. Relative legacy layout
if(NOT LIBCPP_INCLUDE_DIR)
    set(_possible_include_dirs
        "${COMPILER_ROOT}/include/c++/v1"
        "${COMPILER_ROOT}/lib/clang/*/include/c++/v1"
    )
    foreach(_dir ${_possible_include_dirs})
        file(GLOB _expanded_dirs "${_dir}")
        foreach(_expanded_dir ${_expanded_dirs})
            if(EXISTS "${_expanded_dir}" AND IS_DIRECTORY "${_expanded_dir}")
                set(LIBCPP_INCLUDE_DIR "${_expanded_dir}")
                break()
            endif()
        endforeach()
        if(LIBCPP_INCLUDE_DIR)
            break()
        endif()
    endforeach()
endif()

# 5. llvm-config heuristic
if(NOT LIBCPP_INCLUDE_DIR)
    find_program(LLVM_CONFIG_EXECUTABLE NAMES llvm-config llvm-config-20 llvm-config-19)
    if(LLVM_CONFIG_EXECUTABLE)
        execute_process(COMMAND ${LLVM_CONFIG_EXECUTABLE} --includedir
                        OUTPUT_VARIABLE _llvm_inc OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
        if(_llvm_inc)
            set(_candidate_inc "${_llvm_inc}/c++/v1")
            if(EXISTS "${_candidate_inc}")
                set(LIBCPP_INCLUDE_DIR "${_candidate_inc}")
            endif()
        endif()
        execute_process(COMMAND ${LLVM_CONFIG_EXECUTABLE} --libdir
                        OUTPUT_VARIABLE _llvm_lib OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
        if(_llvm_lib AND NOT LIBCPP_LIB_DIR)
            if(EXISTS "${_llvm_lib}/libc++.so" OR EXISTS "${_llvm_lib}/libc++.a" OR EXISTS "${_llvm_lib}/libc++.dylib")
                set(LIBCPP_LIB_DIR "${_llvm_lib}")
            endif()
        endif()
    endif()
endif()

# Library dir probing (if not yet found)
if(NOT LIBCPP_LIB_DIR)
    set(_possible_lib_dirs
        "${COMPILER_ROOT}/lib"
        "${COMPILER_ROOT}/lib/c++"
        "/usr/lib"
        "/usr/lib/llvm-20/lib"
    )
    foreach(_dir ${_possible_lib_dirs})
        if(EXISTS "${_dir}" AND IS_DIRECTORY "${_dir}")
            if(EXISTS "${_dir}/libc++.so" OR EXISTS "${_dir}/libc++.a" OR EXISTS "${_dir}/libc++.dylib")
                set(LIBCPP_LIB_DIR "${_dir}")
                break()
            endif()
        endif()
    endforeach()
endif()

# Configure libc++ usage
if(LIBCPP_INCLUDE_DIR AND LIBCPP_LIB_DIR)
    message(STATUS "Using detected libc++:")
    message(STATUS "  Compiler: ${CMAKE_CXX_COMPILER}")
    message(STATUS "  Headers: ${LIBCPP_INCLUDE_DIR}")
    message(STATUS "  Libraries: ${LIBCPP_LIB_DIR}")
    add_compile_options(-stdlib=libc++ -isystem "${LIBCPP_INCLUDE_DIR}")
    add_link_options(-stdlib=libc++ -L"${LIBCPP_LIB_DIR}" -rpath "${LIBCPP_LIB_DIR}")
    set(HALO_LIBCPP_CXXFLAGS "-stdlib=libc++ -isystem ${LIBCPP_INCLUDE_DIR}" CACHE INTERNAL "libc++ compile flags")
    set(HALO_LIBCPP_LINKFLAGS "-stdlib=libc++ -L${LIBCPP_LIB_DIR} -rpath ${LIBCPP_LIB_DIR}" CACHE INTERNAL "libc++ link flags")
elseif(LIBCPP_LIB_DIR AND NOT LIBCPP_INCLUDE_DIR)
    # Library found but headers path missing – rely on system include search, just enforce stdlib switch
    message(WARNING "libc++ library found at ${LIBCPP_LIB_DIR} but headers path not found; proceeding with -stdlib=libc++ without explicit -isystem")
    add_compile_options(-stdlib=libc++)
    add_link_options(-stdlib=libc++ -L"${LIBCPP_LIB_DIR}" -rpath "${LIBCPP_LIB_DIR}")
    set(HALO_LIBCPP_CXXFLAGS "-stdlib=libc++" CACHE INTERNAL "libc++ compile flags")
    set(HALO_LIBCPP_LINKFLAGS "-stdlib=libc++ -L${LIBCPP_LIB_DIR} -rpath ${LIBCPP_LIB_DIR}" CACHE INTERNAL "libc++ link flags")
else()
    message(STATUS "libc++ not explicitly located (headers/lib); enforcing -stdlib=libc++ via system search paths")
    add_compile_options(-stdlib=libc++)
    add_link_options(-stdlib=libc++)
    set(HALO_LIBCPP_CXXFLAGS "-stdlib=libc++" CACHE INTERNAL "libc++ compile flags")
    set(HALO_LIBCPP_LINKFLAGS "-stdlib=libc++" CACHE INTERNAL "libc++ link flags")
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

# -----------------------------------------------------------------------------
# Compiler feature / warning flag probes (performed once)
# -----------------------------------------------------------------------------
include(CheckCXXCompilerFlag)
check_cxx_compiler_flag("-Wno-gnu-zero-variadic-macro-arguments" COMPILER_SUPPORTS_WNO_GNU_ZERO_VARIADIC_MACRO_ARGS)
check_cxx_compiler_flag("-Wno-sign-compare" COMPILER_SUPPORTS_WNO_SIGN_COMPARE)
check_cxx_compiler_flag("-Wno-extra-semi" COMPILER_SUPPORTS_WNO_EXTRA_SEMI)
check_cxx_compiler_flag("-Wno-gnu-statement-expression" COMPILER_SUPPORTS_WNO_GNU_STMT_EXPR)

###############################################################################
# LTO mode selection
# HALO_LTO_MODE: full | thin | off  (default full for optimized builds)
# Applies to root targets; third-party propagation handled in ThirdpartyUtils.
###############################################################################
set(HALO_LTO_MODE "full" CACHE STRING "LTO mode (full|thin|off)")
set_property(CACHE HALO_LTO_MODE PROPERTY STRINGS full thin off)

if(CMAKE_BUILD_TYPE MATCHES "^Release$" OR CMAKE_BUILD_TYPE MATCHES "^RelWithDebInfo$")
    if(NOT HALO_LTO_MODE STREQUAL "off")
        include(CheckIPOSupported)
        check_ipo_supported(RESULT _ipo_supported OUTPUT _ipo_msg)
        if(_ipo_supported)
            set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)
            if(HALO_LTO_MODE STREQUAL "thin")
                add_compile_options(-flto=thin)
                add_link_options(-flto=thin)
                message(STATUS "[LTO] ThinLTO enabled for ${CMAKE_BUILD_TYPE}")
            elseif(HALO_LTO_MODE STREQUAL "full")
                # Explicit full to override any inherited thin flags
                add_compile_options(-flto)
                add_link_options(-flto)
                message(STATUS "[LTO] Full LTO enabled for ${CMAKE_BUILD_TYPE}")
            else()
                message(WARNING "[LTO] Unknown HALO_LTO_MODE='${HALO_LTO_MODE}', falling back to full")
                add_compile_options(-flto)
                add_link_options(-flto)
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
        -Wall                    # Enable most warnings
        -Wextra                  # Enable extra warnings
        -Wpedantic               # Enable pedantic warnings
        -Wno-unused-parameter    # Suppress unused parameter warnings
        -fno-omit-frame-pointer  # Keep frame pointers for better stack traces
        -fno-optimize-sibling-calls  # Better debugging experience
    )

    if(COMPILER_SUPPORTS_WNO_GNU_ZERO_VARIADIC_MACRO_ARGS)
        add_compile_options(-Wno-gnu-zero-variadic-macro-arguments)
    endif()

    if(COMPILER_SUPPORTS_WNO_SIGN_COMPARE)
        add_compile_options(-Wno-sign-compare)
    endif()
    if(COMPILER_SUPPORTS_WNO_EXTRA_SEMI)
        add_compile_options(-Wno-extra-semi)
    endif()
    if(COMPILER_SUPPORTS_WNO_GNU_STMT_EXPR)
        add_compile_options(-Wno-gnu-statement-expression)
    endif()
    
    if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        # Enable libc++ debug mode (instead of libstdc++)
        add_compile_definitions(
            _LIBCPP_DEBUG=1          # Enable libc++ debug mode
            _LIBCPP_DEBUG_USE_EXCEPTIONS=1  # Enable debug exceptions
        )
    else()
        message(FATAL_ERROR "This project requires Clang compiler. Current compiler: ${CMAKE_CXX_COMPILER_ID}")
    endif()
elseif(CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
    # RelWithDebInfo: Optimized with debug symbols for profiling (Clang only)
    # Probe support for -fno-inline-small-functions (not all clang builds enable it)
    check_cxx_compiler_flag("-fno-inline-small-functions" COMPILER_SUPPORTS_FNO_INLINE_SMALL_FUNCTIONS)
    if(COMPILER_SUPPORTS_FNO_INLINE_SMALL_FUNCTIONS)
        add_compile_options(
            -fno-omit-frame-pointer  # Keep frame pointers for profiling
            -fno-inline-small-functions  # Better profiling granularity
        )
    else()
        add_compile_options(
            -fno-omit-frame-pointer  # Keep frame pointers for profiling
        )
        message(STATUS "[profiling] Compiler does not support -fno-inline-small-functions; skipping flag")
    endif()
    
    # Enable some debug definitions but not heavy runtime checks
    add_compile_definitions(
        ENABLE_PROFILING         # Custom profiling hooks
        DEBUG_SYMBOLS_ENABLED    # Indicate debug symbols are available
    )
elseif(CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
    # MinSizeRel: Focus on minimal binary size (Clang only)
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
