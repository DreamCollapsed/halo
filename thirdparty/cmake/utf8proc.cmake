## utf8proc third-party integration
# Reference: https://github.com/JuliaStrings/utf8proc

thirdparty_build_cmake_library("utf8proc"
    EXTRACT_PATTERN "${THIRDPARTY_SRC_DIR}/utf8proc-*"
    CMAKE_ARGS
        -DUTF8PROC_ENABLE_TESTING=OFF
        -DBUILD_SHARED_LIBS=OFF
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/utf8proc/lib/libutf8proc.a"
        "${THIRDPARTY_INSTALL_DIR}/utf8proc/include/utf8proc.h"
)

if(NOT TARGET utf8proc::halo_utf8proc)
    add_library(utf8proc_halo_thirdparty_static STATIC IMPORTED GLOBAL)
    set_target_properties(utf8proc_halo_thirdparty_static PROPERTIES
        IMPORTED_LOCATION "${UTF8PROC_INSTALL_DIR}/lib/libutf8proc.a"
        INTERFACE_INCLUDE_DIRECTORIES "${UTF8PROC_INSTALL_DIR}/include"
    )
    add_library(utf8proc::halo_utf8proc ALIAS utf8proc_halo_thirdparty_static)
endif()
message(STATUS "utf8proc found and exported globally: ${UTF8PROC_INSTALL_DIR}")
