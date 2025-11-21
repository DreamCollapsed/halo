# glog third-party integration
# Reference: https://github.com/google/glog

set(_GLOG_LIBUNWIND_INCLUDE_DIR "${THIRDPARTY_INSTALL_DIR}/llvm-project/include")

thirdparty_combine_flags(_glog_cxx_flags FRAGMENTS "${HALO_CMAKE_CXX_FLAGS_BASE}" "-I${_GLOG_LIBUNWIND_INCLUDE_DIR}")

thirdparty_build_cmake_library("glog"
    CMAKE_ARGS
        -DWITH_GFLAGS=ON
        -DWITH_GTEST=OFF
        -DWITH_PKGCONFIG=OFF
        -DWITH_UNWIND=libunwind
        -DUnwind_INCLUDE_DIR=${_GLOG_LIBUNWIND_INCLUDE_DIR}
        -DUnwind_LIBRARY=${THIRDPARTY_INSTALL_DIR}/llvm-project/lib/libunwind.a
        -DCMAKE_CXX_FLAGS=${_glog_cxx_flags}
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/glog/lib/cmake/glog/glog-config.cmake"
        "${THIRDPARTY_INSTALL_DIR}/glog/lib/libglog.a"
        "${THIRDPARTY_INSTALL_DIR}/glog/include/glog/logging.h"
        "${THIRDPARTY_INSTALL_DIR}/glog/include/glog/log_severity.h"
)

find_package(glog CONFIG REQUIRED)

thirdparty_map_imported_config(glog::glog)

if(TARGET gflags::gflags AND NOT TARGET gflags)
    add_library(gflags ALIAS gflags::gflags)
endif()
