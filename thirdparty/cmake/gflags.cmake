# gflags third-party integration
# Reference: https://github.com/gflags/gflags

thirdparty_build_cmake_library("gflags"
    CMAKE_ARGS
        -DBUILD_STATIC_LIBS=ON
        -DINSTALL_HEADERS=ON
        -DGFLAGS_NAMESPACE=gflags
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/gflags/lib/cmake/gflags/gflags-config.cmake"
        "${THIRDPARTY_INSTALL_DIR}/gflags/lib/libgflags.a"
        "${THIRDPARTY_INSTALL_DIR}/gflags/include/gflags/gflags.h"
        "${THIRDPARTY_INSTALL_DIR}/gflags/include/gflags/gflags_declare.h"
)

set(GFLAGS_USE_TARGET_NAMESPACE TRUE CACHE BOOL "Use gflags target namespace")
set(GFLAGS_SHARED FALSE CACHE BOOL "Use static gflags library")
set(GFLAGS_NOTHREADS FALSE CACHE BOOL "Use threaded gflags library")
find_package(gflags CONFIG REQUIRED)

if(TARGET gflags::gflags_static AND NOT TARGET gflags)
    add_library(gflags ALIAS gflags::gflags_static)
endif()

if(TARGET gflags::gflags_nothreads_static AND NOT TARGET gflags_nothreads_static)
    add_library(gflags_nothreads_static ALIAS gflags::gflags_nothreads_static)
elseif(TARGET gflags::gflags_static AND NOT TARGET gflags_nothreads_static)
    add_library(gflags_nothreads_static ALIAS gflags::gflags_static)
endif()

message(STATUS "gflags found and exported globally: ${GFLAGS_INSTALL_DIR}")
