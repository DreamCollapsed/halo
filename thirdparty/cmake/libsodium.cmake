# libsodium third-party integration
# Reference: https://github.com/jedisct1/libsodium
# libsodium is a modern, easy-to-use software library for encryption, decryption, 
# signatures, password hashing and more.

# Use the standardized build function for autotools-based libraries
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

# Additional libsodium-specific setup
set(LIBSODIUM_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/libsodium")
get_filename_component(LIBSODIUM_INSTALL_DIR "${LIBSODIUM_INSTALL_DIR}" ABSOLUTE)

# Create modern CMake targets for libsodium
if(EXISTS "${LIBSODIUM_INSTALL_DIR}/lib/libsodium.a")
    # Create libsodium::libsodium target
    if(NOT TARGET libsodium::libsodium)
        add_library(libsodium::libsodium STATIC IMPORTED)
        set_target_properties(libsodium::libsodium PROPERTIES
            IMPORTED_LOCATION "${LIBSODIUM_INSTALL_DIR}/lib/libsodium.a"
            INTERFACE_INCLUDE_DIRECTORIES "${LIBSODIUM_INSTALL_DIR}/include"
        )
        
        # libsodium requires no additional system libraries on most platforms
        # but may need pthread on some systems
        find_package(Threads QUIET)
        if(Threads_FOUND)
            set_target_properties(libsodium::libsodium PROPERTIES
                INTERFACE_LINK_LIBRARIES "Threads::Threads"
            )
        endif()
        
        message(STATUS "Created libsodium::libsodium target")
    endif()
    
    message(STATUS "libsodium found and exported globally: ${LIBSODIUM_INSTALL_DIR}")
else()
    message(WARNING "libsodium installation not found at ${LIBSODIUM_INSTALL_DIR}")
endif()
