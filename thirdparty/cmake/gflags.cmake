# gflags third-party integration
# Reference: https://github.com/gflags/gflags

# Use the standardized build function for simple CMake libraries
thirdparty_build_cmake_library("gflags"
    CMAKE_ARGS
        -DBUILD_STATIC_LIBS=ON
        -DBUILD_TESTING=OFF
        -DINSTALL_HEADERS=ON
        -DGFLAGS_NAMESPACE=gflags
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/gflags/lib/cmake/gflags/gflags-config.cmake"
        "${THIRDPARTY_INSTALL_DIR}/gflags/lib/libgflags.a"
        "${THIRDPARTY_INSTALL_DIR}/gflags/include/gflags/gflags.h"
        "${THIRDPARTY_INSTALL_DIR}/gflags/include/gflags/gflags_declare.h"
)

# Additional gflags-specific setup
set(GFLAGS_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/gflags")
get_filename_component(GFLAGS_INSTALL_DIR "${GFLAGS_INSTALL_DIR}" ABSOLUTE)

if(EXISTS "${GFLAGS_INSTALL_DIR}/lib/cmake/gflags/gflags-config.cmake")
    set(gflags_DIR "${GFLAGS_INSTALL_DIR}/lib/cmake/gflags" CACHE PATH "Path to installed gflags cmake config" FORCE)
    
    # Set gflags configuration variables to ensure gflags::gflags target is created
    set(GFLAGS_USE_TARGET_NAMESPACE TRUE CACHE BOOL "Use gflags target namespace")
    set(GFLAGS_SHARED FALSE CACHE BOOL "Use static gflags library")
    set(GFLAGS_NOTHREADS FALSE CACHE BOOL "Use threaded gflags library")
    
    # Immediately find and import gflags package to create targets
    find_package(gflags REQUIRED CONFIG QUIET)
    
    # Create legacy alias for Folly compatibility
    if(TARGET gflags::gflags AND NOT TARGET gflags_nothreads_static)
        add_library(gflags_nothreads_static ALIAS gflags::gflags)
        message(STATUS "Created gflags_nothreads_static alias for gflags::gflags")
    endif()
    
    message(STATUS "gflags found and exported globally: ${GFLAGS_INSTALL_DIR}")
else()
    message(WARNING "gflags installation not found at ${GFLAGS_INSTALL_DIR}")
endif()
