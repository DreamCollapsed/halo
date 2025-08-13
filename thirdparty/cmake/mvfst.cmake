# mvfst (QUIC) third-party integration
# Reference: https://github.com/facebook/mvfst

thirdparty_setup_directories("mvfst")

thirdparty_get_optimization_flags(_opt_flags COMPONENT mvfst)
list(APPEND _opt_flags
    -DCMAKE_INSTALL_PREFIX=${MVFST_INSTALL_DIR}

    -DCMAKE_POLICY_DEFAULT_CMP0167=OLD

    -DCMAKE_MODULE_PATH=${MVFST_SOURCE_DIR}/build/fbcode_builder/CMake

    # OpenSSL
    -DOPENSSL_ROOT_DIR=${THIRDPARTY_INSTALL_DIR}/openssl
    -DOPENSSL_INCLUDE_DIR=${THIRDPARTY_INSTALL_DIR}/openssl/include
    -DOPENSSL_SSL_LIBRARY=${THIRDPARTY_INSTALL_DIR}/openssl/lib/libssl.a
    -DOPENSSL_CRYPTO_LIBRARY=${THIRDPARTY_INSTALL_DIR}/openssl/lib/libcrypto.a

    # Sodium
    -Dsodium_DIR=${THIRDPARTY_INSTALL_DIR}/libsodium
    -Dsodium_USE_STATIC_LIBS=ON

    # jemalloc
    -DCMAKE_CXX_FLAGS=-I${THIRDPARTY_INSTALL_DIR}/jemalloc/include\ -include\ ${THIRDPARTY_INSTALL_DIR}/jemalloc/include/jemalloc_prefix_compat.h
)

thirdparty_build_cmake_library("mvfst"
    CMAKE_ARGS ${_opt_flags}
    VALIDATION_FILES
        "${MVFST_INSTALL_DIR}/lib/libmvfst_transport.a"
        "${MVFST_INSTALL_DIR}/lib/cmake/mvfst/mvfst-config.cmake"
)

find_package(mvfst CONFIG REQUIRED)
message(STATUS "mvfst imported into superproject: ${MVFST_INSTALL_DIR}")
