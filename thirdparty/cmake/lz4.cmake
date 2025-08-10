# lz4 third-party integration
# Reference: https://github.com/lz4/lz4

thirdparty_build_cmake_library("lz4"
    SOURCE_SUBDIR "build/cmake"
    VALIDATION_FILES
        "${LZ4_INSTALL_DIR}/lib/liblz4.a"
        "${LZ4_INSTALL_DIR}/include/lz4.h"
    CMAKE_ARGS
        -DLZ4_BUILD_CLI=OFF
        -DLZ4_BUILD_LEGACY_LIBS=OFF
        -DLZ4_BUNDLE_MODE=OFF
        -DLZ4_POSITION_INDEPENDENT_CODE=ON
)

set(LZ4_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/lz4")
get_filename_component(LZ4_INSTALL_DIR "${LZ4_INSTALL_DIR}" ABSOLUTE)

if(EXISTS "${LZ4_INSTALL_DIR}/lib/cmake/lz4/lz4Config.cmake")
    find_package(lz4 CONFIG REQUIRED)
    
    if(TARGET lz4::lz4_static AND NOT TARGET LZ4::lz4_static)
        add_library(LZ4::lz4_static ALIAS lz4::lz4_static)
    endif()
    if(TARGET lz4::lz4 AND NOT TARGET LZ4::lz4)
        add_library(LZ4::lz4 ALIAS lz4::lz4)
    endif()

    message(STATUS "lz4 found and imported: ${LZ4_INSTALL_DIR}")
else()
    message(FATAL_ERROR "lz4 installation not found at ${LZ4_INSTALL_DIR}")
endif()
