# Wangle third-party integration
# Reference: https://github.com/facebook/wangle

thirdparty_setup_directories("wangle")

# jemalloc flags: only set on Apple platforms to avoid header conflicts on Linux
if(APPLE)
    # On macOS force include the prefix compat header for symbol remapping.
    # Include both the directory and the compatibility header.
    set(_WANGLE_JEMALLOC_FLAGS "-I${THIRDPARTY_INSTALL_DIR}/jemalloc/include -include ${THIRDPARTY_INSTALL_DIR}/jemalloc/include/jemalloc_prefix_compat.h")
else()
    # On Linux, avoid jemalloc include directory to prevent posix_memalign exception spec conflicts.
    set(_WANGLE_JEMALLOC_FLAGS "")
endif()

# Combine base libc++ flags + jemalloc flags
thirdparty_combine_flags(_WANGLE_COMBINED_CXX_FLAGS FRAGMENTS "${HALO_CMAKE_CXX_FLAGS_BASE}" "${_WANGLE_JEMALLOC_FLAGS}" "-DGLOG_USE_GLOG_EXPORT")

set(_wangle_args
    -DCMAKE_INSTALL_PREFIX=${WANGLE_INSTALL_DIR}

    -DCMAKE_POLICY_DEFAULT_CMP0167=OLD

    -DCMAKE_MODULE_PATH=${WANGLE_SOURCE_DIR}/build/fbcode_builder/CMake

    # OPENSSL
    -DOPENSSL_ROOT_DIR=${THIRDPARTY_INSTALL_DIR}/openssl
    -DOPENSSL_INCLUDE_DIR=${THIRDPARTY_INSTALL_DIR}/openssl/include
    -DOPENSSL_SSL_LIBRARY=${THIRDPARTY_INSTALL_DIR}/openssl/lib/libssl.a
    -DOPENSSL_CRYPTO_LIBRARY=${THIRDPARTY_INSTALL_DIR}/openssl/lib/libcrypto.a

    # LIBEVENT
    -DLIBEVENT_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/libevent/include
    -DLIBEVENT_LIB:FILEPATH=${THIRDPARTY_INSTALL_DIR}/libevent/lib/libevent.a

    -DCMAKE_CXX_FLAGS=${_WANGLE_COMBINED_CXX_FLAGS}
)

thirdparty_build_cmake_library("wangle"
    SOURCE_SUBDIR "${WANGLE_NAME}"
    CMAKE_ARGS ${_wangle_args}
    VALIDATION_FILES
        "${WANGLE_INSTALL_DIR}/lib/libwangle.a"
        "${WANGLE_INSTALL_DIR}/include/wangle/channel/Pipeline.h"
)

halo_find_package(wangle CONFIG REQUIRED)

thirdparty_map_imported_config(wangle::wangle)
