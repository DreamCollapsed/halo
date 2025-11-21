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

# Clean up shared libraries if they were built, to prevent accidental linking
file(GLOB _zlib_shared "${THIRDPARTY_INSTALL_DIR}/zlib/lib/*.dylib" "${THIRDPARTY_INSTALL_DIR}/zlib/lib/*.so*")
if(_zlib_shared)
    file(REMOVE ${_zlib_shared})
    message(DEBUG "[zlib] Removed shared libraries to enforce static linking")
endif()

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
else()
    message(FATAL_ERROR "zlib installation not found at ${ZLIB_INSTALL_DIR}")
endif()
