# xz third-party integration
# Reference: https://github.com/tukaani-project/xz

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

find_package(liblzma CONFIG REQUIRED)

set(XZ_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/xz")
get_filename_component(XZ_INSTALL_DIR "${XZ_INSTALL_DIR}" ABSOLUTE)
if(TARGET liblzma::liblzma)
    message(DEBUG "xz found via CMake config and exported globally: ${XZ_INSTALL_DIR}")
elseif(EXISTS "${XZ_INSTALL_DIR}/lib/cmake/liblzma/liblzma-config.cmake")
    find_package(liblzma CONFIG REQUIRED)
    if(TARGET liblzma::liblzma)
        message(DEBUG "xz found via explicit liblzma_DIR and exported globally: ${XZ_INSTALL_DIR}")
    endif()
endif()

if(NOT TARGET liblzma::liblzma AND EXISTS "${XZ_INSTALL_DIR}/lib/pkgconfig/liblzma.pc")
    find_package(PkgConfig CONFIG REQUIRED)
    if(PkgConfig_FOUND)
        set(ENV{PKG_CONFIG_PATH} "${XZ_INSTALL_DIR}/lib/pkgconfig:$ENV{PKG_CONFIG_PATH}")
        pkg_check_modules(LIBLZMA QUIET liblzma)
        if(LIBLZMA_FOUND)
            if(NOT TARGET liblzma::liblzma)
                add_library(liblzma::liblzma STATIC IMPORTED GLOBAL)
                set_target_properties(liblzma::liblzma PROPERTIES
                    IMPORTED_LOCATION "${XZ_INSTALL_DIR}/lib/liblzma.a"
                    INTERFACE_INCLUDE_DIRECTORIES "${XZ_INSTALL_DIR}/include"
                )
            endif()
            message(DEBUG "xz found via pkgconfig and exported globally: ${XZ_INSTALL_DIR}")
        endif()
    endif()
endif()

if(NOT TARGET liblzma::liblzma)
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
        message(FATAL_ERROR "xz installation not found at ${XZ_INSTALL_DIR}")
    endif()
endif()
