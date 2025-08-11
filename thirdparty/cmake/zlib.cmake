# zlib third-party integration
# Reference: https://github.com/madler/zlib

thirdparty_build_cmake_library("zlib"
    CMAKE_ARGS
        -DZLIB_BUILD_EXAMPLES=OFF
        -DZLIB_BUILD_TESTS=OFF
        -DZLIB_COMPAT=OFF
        -DZLIB_ENABLE_TESTS=OFF
        -DZLIB_DUAL_LINK=OFF
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/zlib/lib/libz.a"
        "${THIRDPARTY_INSTALL_DIR}/zlib/include/zlib.h"
)

set(ZLIB_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/zlib")
get_filename_component(ZLIB_INSTALL_DIR "${ZLIB_INSTALL_DIR}" ABSOLUTE)

if(EXISTS "${ZLIB_INSTALL_DIR}/lib/libz.a" AND EXISTS "${ZLIB_INSTALL_DIR}/include/zlib.h")
    if(NOT TARGET zlib::zlib)
        add_library(zlib::zlib STATIC IMPORTED GLOBAL)
        set_target_properties(zlib::zlib PROPERTIES
            IMPORTED_LOCATION "${ZLIB_INSTALL_DIR}/lib/libz.a"
            INTERFACE_INCLUDE_DIRECTORIES "${ZLIB_INSTALL_DIR}/include"
            INTERFACE_COMPILE_DEFINITIONS "ZLIB_STATIC"
        )
    endif()
    if(NOT TARGET ZLIB::ZLIB)
        add_library(ZLIB::ZLIB ALIAS zlib::zlib)
    endif()
    message(STATUS "zlib found and exported globally: ${ZLIB_INSTALL_DIR}")
else()
    message(FATAL_ERROR "zlib installation not found at ${ZLIB_INSTALL_DIR}")
endif()
