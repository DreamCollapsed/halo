# xxHash third-party integration
# Reference: https://github.com/Cyan4973/xxHash

thirdparty_build_autotools_library("xxhash"
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/xxhash/lib/libxxhash.a"
        "${THIRDPARTY_INSTALL_DIR}/xxhash/include/xxhash.h"
    MAKE_ARGS
        "install_libxxhash.a" "install_libxxhash.includes" "PREFIX=${THIRDPARTY_INSTALL_DIR}/xxhash" "CFLAGS=-fPIC"
    INSTALL_ARGS
        "install_libxxhash.a" "install_libxxhash.includes" "PREFIX=${THIRDPARTY_INSTALL_DIR}/xxhash" "CFLAGS=-fPIC"
    BUILD_IN_SOURCE
)

add_library(xxhash_thirdparty_static STATIC IMPORTED GLOBAL)
set_target_properties(xxhash_thirdparty_static PROPERTIES
    IMPORTED_LOCATION "${XXHASH_INSTALL_DIR}/lib/libxxhash.a"
    INTERFACE_INCLUDE_DIRECTORIES "${XXHASH_INSTALL_DIR}/include"
)
add_library(xxhash::xxhash ALIAS xxhash_thirdparty_static)

message(STATUS "xxhash build configured and completed during configure time.")
