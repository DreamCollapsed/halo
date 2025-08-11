# Wangle third-party integration
# Reference: https://github.com/facebook/wangle

thirdparty_setup_directories("wangle")

thirdparty_get_optimization_flags(_opt_flags COMPONENT wangle)
list(APPEND _opt_flags
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

    # BOOST
    -DBOOST_ROOT=${THIRDPARTY_INSTALL_DIR}/boost
    -DBOOST_INCLUDEDIR=${THIRDPARTY_INSTALL_DIR}/boost/include
    -DBOOST_LIBRARYDIR=${THIRDPARTY_INSTALL_DIR}/boost/lib
    -DBoost_USE_STATIC_LIBS=ON
    -DBoost_USE_MULTITHREADED=ON
    -DBoost_USE_STATIC_RUNTIME=ON
    -DBoost_NO_SYSTEM_PATHS=ON

    # JEMALLOC
    -DCMAKE_CXX_FLAGS=-I${THIRDPARTY_INSTALL_DIR}/jemalloc/include\ -include\ ${THIRDPARTY_INSTALL_DIR}/jemalloc/include/jemalloc_prefix_compat.h
)

thirdparty_build_cmake_library("wangle"
    SOURCE_SUBDIR "${WANGLE_NAME}"
    CMAKE_ARGS ${_opt_flags}
    VALIDATION_FILES
        "${WANGLE_INSTALL_DIR}/lib/libwangle.a"
        "${WANGLE_INSTALL_DIR}/include/wangle/channel/Pipeline.h"
)

find_package(wangle CONFIG REQUIRED)
message(STATUS "Wangle imported into superproject: ${WANGLE_INSTALL_DIR}")
