# xz third-party integration
# Reference: https://github.com/tukaani-project/xz

# Use the standardized build function for xz
# Note: XZ uses autotools for official releases, but also has CMake support
thirdparty_build_cmake_library("xz"
    CMAKE_ARGS
        -DCREATE_XZ_SYMLINKS=OFF
        -DCREATE_LZMA_SYMLINKS=OFF
        -DENABLE_STATIC=ON
        -DENABLE_SHARED=OFF
        -DENABLE_XZDEC=OFF
        -DENABLE_LZMADEC=OFF
        -DENABLE_LZMAINFO=OFF
        -DENABLE_XZ=OFF
        -DENABLE_LZMA_LINKS=OFF
        -DENABLE_SCRIPTS=OFF
        -DENABLE_DOC=OFF
        -DENABLE_THREADING=ON
        -DENABLE_NLS=OFF
        -DENABLE_DOXYGEN=OFF
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/xz/lib/liblzma.a"
        "${THIRDPARTY_INSTALL_DIR}/xz/include/lzma.h"
)

# Additional xz-specific setup
set(XZ_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/xz")
get_filename_component(XZ_INSTALL_DIR "${XZ_INSTALL_DIR}" ABSOLUTE)

# Try to find the CMake config first
if(EXISTS "${XZ_INSTALL_DIR}/lib/cmake/liblzma/liblzma-config.cmake")
    # Set the directory for find_package
    list(APPEND CMAKE_PREFIX_PATH "${XZ_INSTALL_DIR}")
    set(liblzma_DIR "${XZ_INSTALL_DIR}/lib/cmake/liblzma" CACHE PATH "Path to installed liblzma cmake config" FORCE)
    
    # Import liblzma package
    find_package(liblzma REQUIRED CONFIG QUIET NO_DEFAULT_PATH)
    
    if(TARGET liblzma::liblzma)
        message(STATUS "xz found and exported globally: ${XZ_INSTALL_DIR}")
    else()
        message(WARNING "xz cmake config found but target not created")
    endif()
elseif(EXISTS "${XZ_INSTALL_DIR}/lib/pkgconfig/liblzma.pc")
    # Fallback: use PkgConfig to find liblzma
    find_package(PkgConfig QUIET)
    if(PkgConfig_FOUND)
        set(ENV{PKG_CONFIG_PATH} "${XZ_INSTALL_DIR}/lib/pkgconfig:$ENV{PKG_CONFIG_PATH}")
        pkg_check_modules(LIBLZMA QUIET liblzma)
        if(LIBLZMA_FOUND)
            # Create an IMPORTED target for compatibility
            if(NOT TARGET liblzma::liblzma)
                add_library(liblzma::liblzma STATIC IMPORTED GLOBAL)
                set_target_properties(liblzma::liblzma PROPERTIES
                    IMPORTED_LOCATION "${XZ_INSTALL_DIR}/lib/liblzma.a"
                    INTERFACE_INCLUDE_DIRECTORIES "${XZ_INSTALL_DIR}/include"
                )
            endif()
            message(STATUS "xz found via pkgconfig and exported globally: ${XZ_INSTALL_DIR}")
        endif()
    endif()
else()
    # Fallback: create an IMPORTED target manually
    if(EXISTS "${XZ_INSTALL_DIR}/lib/liblzma.a" AND EXISTS "${XZ_INSTALL_DIR}/include/lzma.h")
        if(NOT TARGET liblzma::liblzma)
            add_library(liblzma::liblzma STATIC IMPORTED GLOBAL)
            set_target_properties(liblzma::liblzma PROPERTIES
                IMPORTED_LOCATION "${XZ_INSTALL_DIR}/lib/liblzma.a"
                INTERFACE_INCLUDE_DIRECTORIES "${XZ_INSTALL_DIR}/include"
            )
        endif()
        message(STATUS "xz found and manually exported globally: ${XZ_INSTALL_DIR}")
    else()
        message(WARNING "xz installation not found at ${XZ_INSTALL_DIR}")
    endif()
endif()
