# libsodium third-party integration
# Reference: https://github.com/jedisct1/libsodium
# libsodium is a modern, easy-to-use software library for encryption, decryption, 
# signatures, password hashing and more.

thirdparty_build_autotools_library("libsodium"
    CONFIGURE_ARGS
        --enable-static
        --disable-shared
        --enable-minimal
        --disable-debug
        --disable-dependency-tracking
        --with-pic
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/libsodium/lib/libsodium.a"
        "${THIRDPARTY_INSTALL_DIR}/libsodium/include/sodium.h"
        "${THIRDPARTY_INSTALL_DIR}/libsodium/lib/pkgconfig/libsodium.pc"
)

if(EXISTS "${LIBSODIUM_INSTALL_DIR}/lib/libsodium.a")
    if(NOT TARGET libsodium::libsodium)
        add_library(libsodium::libsodium STATIC IMPORTED)
        set_target_properties(libsodium::libsodium PROPERTIES
            IMPORTED_LOCATION "${LIBSODIUM_INSTALL_DIR}/lib/libsodium.a"
            INTERFACE_INCLUDE_DIRECTORIES "${LIBSODIUM_INSTALL_DIR}/include"
        )
        find_package(Threads)
        if(Threads_FOUND)
            set_target_properties(libsodium::libsodium PROPERTIES
                INTERFACE_LINK_LIBRARIES "Threads::Threads"
            )
        endif()
        message(DEBUG "Created libsodium::libsodium target")
    endif()
else()
    message(FATAL_ERROR "libsodium installation not found at ${LIBSODIUM_INSTALL_DIR}")
endif()
