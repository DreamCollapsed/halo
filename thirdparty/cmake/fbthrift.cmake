# Facebook Thrift (fbthrift) integration for Halo
# Simplified via thirdparty_build_cmake_library helper.

thirdparty_build_cmake_library("fbthrift"
    CMAKE_ARGS
        -DFBTHRIFT_BUILD_TESTS=OFF
        -DFBTHRIFT_ENABLE_WERROR=OFF
        -DFBTHRIFT_BUILD_EXAMPLES=OFF
        -DFBTHRIFT_ENABLE_TEMPLATES=ON
        -DFBTHRIFT_USE_FOLLY_DYNAMIC=OFF

        # OpenSSL
        -DOPENSSL_ROOT_DIR=${THIRDPARTY_INSTALL_DIR}/openssl
        -DOPENSSL_INCLUDE_DIR=${THIRDPARTY_INSTALL_DIR}/openssl/include
        -DOPENSSL_SSL_LIBRARY=${THIRDPARTY_INSTALL_DIR}/openssl/lib/libssl.a
        -DOPENSSL_CRYPTO_LIBRARY=${THIRDPARTY_INSTALL_DIR}/openssl/lib/libcrypto.a

        # Jemalloc
        -DCMAKE_CXX_FLAGS=-I${THIRDPARTY_INSTALL_DIR}/jemalloc/include\ -include\ ${THIRDPARTY_INSTALL_DIR}/jemalloc/include/jemalloc_prefix_compat.h
    FILE_REPLACEMENTS
        thrift/compiler/ast/ast_visitor.h
        "#pragma once"
        "#pragma once\n\n#include <exception>"
        thrift/compiler/whisker/object.h
        "#pragma once"
        "#pragma once\n\n#include <exception>"
    VALIDATION_FILES
        ${THIRDPARTY_INSTALL_DIR}/fbthrift/lib/libthriftcpp2.a
        ${THIRDPARTY_INSTALL_DIR}/fbthrift/include/thrift/lib/cpp2/Thrift.h
)

find_package(fbthrift CONFIG REQUIRED)
message(STATUS "fbthrift integrated: target FBTHRIFT::thriftcpp2 available (install=${FBTHRIFT_INSTALL_DIR})")
