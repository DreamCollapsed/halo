# Custom override Findgflags.cmake to bypass fizz fbcode_builder module requirement
# Strategy:
# 1. First try to locate a CMake config package from thirdparty install or standard prefixes.
# 2. Do NOT enforce component (static/shared) presence; just pick any available target and
#    create an alias gflags::gflags for consumer code.
# 3. Provide gflags_FOUND variable consistent with find_package convention.

if(TARGET gflags::gflags)
  set(gflags_FOUND TRUE)
  return()
endif()

# User hint variable: GFLAGS_ROOT
if(GFLAGS_ROOT)
  list(APPEND CMAKE_PREFIX_PATH "${GFLAGS_ROOT}")
endif()

# Allow caller to hint custom thirdparty location
if(DEFINED THIRDPARTY_INSTALL_DIR)
  list(APPEND CMAKE_PREFIX_PATH "${THIRDPARTY_INSTALL_DIR}/gflags")
endif()

# Force threaded variant: set cache hints BEFORE config load so that
# gflags-config logic picks a threaded target. We explicitly set
# GFLAGS_NOTHREADS FALSE and allow GFLAGS_SHARED to follow BUILD_SHARED_LIBS.
set(GFLAGS_NOTHREADS FALSE CACHE BOOL "Force threaded gflags" FORCE)

find_package(gflags CONFIG REQUIRED)

if(NOT gflags_FOUND)
  # Try to include config file manually if path known
  set(_GFLAGS_CONFIG "${THIRDPARTY_INSTALL_DIR}/gflags/lib/cmake/gflags/gflags-config.cmake")
  if(EXISTS "${_GFLAGS_CONFIG}")
    include("${_GFLAGS_CONFIG}")
    set(gflags_FOUND TRUE)
  endif()
endif()

if(TARGET gflags::gflags)
  set(gflags_FOUND TRUE)
else()
  # Prefer threaded variants explicitly; reject pure nothreads.
  if(TARGET gflags_shared AND NOT TARGET gflags_nothreads_shared)
    add_library(gflags::gflags ALIAS gflags_shared)
    set(gflags_FOUND TRUE)
  elseif(TARGET gflags_static AND NOT TARGET gflags_nothreads_static)
    add_library(gflags::gflags ALIAS gflags_static)
    set(gflags_FOUND TRUE)
  elseif(TARGET gflags) # Generic aggregated target (threaded)
    add_library(gflags::gflags ALIAS gflags)
    set(gflags_FOUND TRUE)
  endif()
endif()

# Detect if we only have nothreads variants (should fail per request)
if(NOT gflags_FOUND)
  if(TARGET gflags_nothreads_static OR TARGET gflags_nothreads_shared)
    message(FATAL_ERROR "Only 'nothreads' gflags variant found, but threaded variant required.")
  endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(gflags REQUIRED_VARS gflags_FOUND)

if(NOT TARGET gflags::gflags)
  message(FATAL_ERROR "Custom Findgflags.cmake could not locate any gflags target.")
endif()
