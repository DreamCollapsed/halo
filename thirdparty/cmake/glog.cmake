# glog third-party integration
# Reference: https://github.com/google/glog

thirdparty_build_cmake_library("glog"
    DEPENDENCIES "gflags"
    CMAKE_ARGS
        -DWITH_GFLAGS=ON
        -DWITH_GTEST=OFF
        -DWITH_PKGCONFIG=OFF
        -DWITH_UNWIND=OFF
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/glog/lib/cmake/glog/glog-config.cmake"
        "${THIRDPARTY_INSTALL_DIR}/glog/lib/libglog.a"
        "${THIRDPARTY_INSTALL_DIR}/glog/include/glog/logging.h"
        "${THIRDPARTY_INSTALL_DIR}/glog/include/glog/log_severity.h"
)

set(GLOG_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/glog")
get_filename_component(GLOG_INSTALL_DIR "${GLOG_INSTALL_DIR}" ABSOLUTE)

if(EXISTS "${GLOG_INSTALL_DIR}/lib/cmake/glog/glog-config.cmake")
    find_package(glog CONFIG REQUIRED)
    
    if(TARGET gflags::gflags AND NOT TARGET gflags)
        add_library(gflags ALIAS gflags::gflags)
    endif()
else()
    message(FATAL_ERROR "glog installation not found at ${GLOG_INSTALL_DIR}")
endif()
