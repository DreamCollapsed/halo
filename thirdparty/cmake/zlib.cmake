# zlib third-party integration
# Reference: https://github.com/madler/zlib

# Use the standardized build function for zlib
# Note: Zlib uses CMake build system
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

# Additional zlib-specific setup
set(ZLIB_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/zlib")
get_filename_component(ZLIB_INSTALL_DIR "${ZLIB_INSTALL_DIR}" ABSOLUTE)

# Aggressive zlib control - prevent ANY system library usage
# Clear all existing CMake zlib-related variables
unset(ZLIB_LIBRARY CACHE)
unset(ZLIB_LIBRARIES CACHE)
unset(ZLIB_INCLUDE_DIR CACHE)
unset(ZLIB_INCLUDE_DIRS CACHE)
unset(ZLIB_ROOT CACHE)
unset(ZLIB_FOUND CACHE)
unset(ZLIB_DIR CACHE)

# Force exclusive use of our compiled library
set(ZLIB_LIBRARY "${ZLIB_INSTALL_DIR}/lib/libz.a" CACHE FILEPATH "ZLIB library path" FORCE)
set(ZLIB_LIBRARIES "${ZLIB_INSTALL_DIR}/lib/libz.a" CACHE STRING "ZLIB libraries" FORCE)
set(ZLIB_INCLUDE_DIR "${ZLIB_INSTALL_DIR}/include" CACHE PATH "ZLIB include directory" FORCE)
set(ZLIB_INCLUDE_DIRS "${ZLIB_INSTALL_DIR}/include" CACHE STRING "ZLIB include directories" FORCE)
set(ZLIB_ROOT "${ZLIB_INSTALL_DIR}" CACHE PATH "ZLIB root directory" FORCE)
set(ZLIB_FOUND TRUE CACHE BOOL "ZLIB found status" FORCE)
set(ZLIB_VERSION_STRING "1.3.1" CACHE STRING "ZLIB version" FORCE)

if(EXISTS "${ZLIB_LIBRARY}" AND EXISTS "${ZLIB_INCLUDE_DIR}/zlib.h")
    if(TARGET zlib::zlib)
        unset(zlib::zlib)
    endif()
    if(TARGET ZLIB::ZLIB)
        unset(ZLIB::ZLIB)
    endif()
    
    add_library(zlib_thirdparty_static STATIC IMPORTED GLOBAL)
    set_target_properties(zlib_thirdparty_static PROPERTIES
        IMPORTED_LOCATION "${ZLIB_LIBRARY}"
        INTERFACE_INCLUDE_DIRECTORIES "${ZLIB_INCLUDE_DIR}"
        INTERFACE_COMPILE_DEFINITIONS "ZLIB_STATIC"
        IMPORTED_LINK_INTERFACE_LIBRARIES ""
        IMPORTED_NO_SONAME TRUE
    )
    
    add_library(zlib::zlib ALIAS zlib_thirdparty_static)
    add_library(ZLIB::ZLIB ALIAS zlib_thirdparty_static)
    
    message(STATUS "zlib found and exported globally: ${ZLIB_INSTALL_DIR}")
    message(STATUS "zlib library: ${ZLIB_LIBRARY}")
    message(STATUS "zlib version: 1.3.1 (forced)")
else()
    message(WARNING "zlib installation not found at ${ZLIB_INSTALL_DIR}")
endif()
