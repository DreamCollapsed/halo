# glog third-party integration
# Reference: https://github.com/google/glog

# Use the standardized build function for simple CMake libraries
thirdparty_build_cmake_library("glog"
    DEPENDENCIES "gflags"
    CMAKE_ARGS
        -DBUILD_TESTING=OFF
        -DWITH_GFLAGS=ON
        -DWITH_GTEST=OFF
        -DWITH_PKGCONFIG=OFF
        -DWITH_UNWIND=OFF
        -DBUILD_SHARED_LIBS=OFF
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/glog/lib/cmake/glog/glog-config.cmake"
        "${THIRDPARTY_INSTALL_DIR}/glog/lib/libglog.a"
        "${THIRDPARTY_INSTALL_DIR}/glog/include/glog/logging.h"
        "${THIRDPARTY_INSTALL_DIR}/glog/include/glog/log_severity.h"
)

# Additional glog-specific setup
set(GLOG_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/glog")
get_filename_component(GLOG_INSTALL_DIR "${GLOG_INSTALL_DIR}" ABSOLUTE)

if(EXISTS "${GLOG_INSTALL_DIR}/lib/cmake/glog/glog-config.cmake")
    set(glog_DIR "${GLOG_INSTALL_DIR}/lib/cmake/glog" CACHE PATH "Path to installed glog cmake config" FORCE)
    message(STATUS "glog found and exported globally: ${GLOG_INSTALL_DIR}")
    
    # Load glog package first to ensure glog::glog target is available
    find_package(glog REQUIRED CONFIG HINTS "${GLOG_INSTALL_DIR}/lib/cmake/glog")
    
    # Create alias for backward compatibility: glog -> gflags::gflags
    # This solves the issue where glog links to "gflags" instead of "gflags::gflags"
    if(TARGET gflags::gflags AND NOT TARGET gflags)
        add_library(gflags ALIAS gflags::gflags)
        message(STATUS "Created gflags alias for gflags::gflags to fix glog dependency")
    endif()
else()
    message(WARNING "glog installation not found at ${GLOG_INSTALL_DIR}")
endif()
