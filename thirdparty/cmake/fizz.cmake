# Fizz third-party integration
# Reference: https://github.com/facebookincubator/fizz

thirdparty_setup_directories("fizz")

thirdparty_get_optimization_flags(_opt_flags COMPONENT fizz)
list(APPEND _opt_flags
    -DCMAKE_INSTALL_PREFIX=${FIZZ_INSTALL_DIR}

    -DCMAKE_POLICY_DEFAULT_CMP0167=OLD

    -DCMAKE_MODULE_PATH=${FIZZ_SOURCE_DIR}/build/fbcode_builder/CMake

    # Sodium
    -Dsodium_USE_STATIC_LIBS=ON
    -Dsodium_DIR=${THIRDPARTY_INSTALL_DIR}/libsodium
    -Dsodium_PKG_STATIC_FOUND=TRUE
    -Dsodium_PKG_STATIC_LIBRARIES=libsodium.a
    -Dsodium_PKG_STATIC_LIBRARY_DIRS=${THIRDPARTY_INSTALL_DIR}/libsodium/lib
    -Dsodium_PKG_STATIC_INCLUDE_DIRS=${THIRDPARTY_INSTALL_DIR}/libsodium/include

    # OpenSSL
    -DOPENSSL_ROOT_DIR=${THIRDPARTY_INSTALL_DIR}/openssl
    -DOPENSSL_INCLUDE_DIR=${THIRDPARTY_INSTALL_DIR}/openssl/include
    -DOPENSSL_SSL_LIBRARY=${THIRDPARTY_INSTALL_DIR}/openssl/lib/libssl.a
    -DOPENSSL_CRYPTO_LIBRARY=${THIRDPARTY_INSTALL_DIR}/openssl/lib/libcrypto.a

    # JEMALLOC
    -DCMAKE_CXX_FLAGS=-I${THIRDPARTY_INSTALL_DIR}/jemalloc/include\ -include\ ${THIRDPARTY_INSTALL_DIR}/jemalloc/include/jemalloc_prefix_compat.h
)

thirdparty_build_cmake_library("fizz"
    SOURCE_SUBDIR "${FIZZ_NAME}"
    CMAKE_ARGS ${_opt_flags}
    FILE_REPLACEMENTS
        "fizz/protocol/AsyncFizzBase.h"
        "  class FizzMsgHdr;"
        "  class FizzMsgHdr;
  struct FizzMsgHdrDeleter {
    void operator()(FizzMsgHdr* p);
  };"
        "fizz/protocol/AsyncFizzBase.h" 
        "  std::unique_ptr<FizzMsgHdr> msgHdr_;"
        "  std::unique_ptr<FizzMsgHdr, FizzMsgHdrDeleter> msgHdr_;"
        "fizz/protocol/AsyncFizzBase.cpp"
        "class AsyncFizzBase::FizzMsgHdr : public folly::EventRecvmsgCallback::MsgHdr {"
        "void AsyncFizzBase::FizzMsgHdrDeleter::operator()(FizzMsgHdr* p) {
  delete p;
}

class AsyncFizzBase::FizzMsgHdr : public folly::EventRecvmsgCallback::MsgHdr {"
    VALIDATION_FILES
        "${FIZZ_INSTALL_DIR}/lib/libfizz.a"
        "${FIZZ_INSTALL_DIR}/include/fizz/fizz-config.h"
)

set(CMAKE_MODULE_PATH ${FIZZ_SOURCE_DIR}/build/fbcode_builder/CMake ${CMAKE_MODULE_PATH})

# Ensure Sodium variables are available for fizz-config.cmake
set(sodium_USE_STATIC_LIBS ON)
set(sodium_PKG_STATIC_FOUND TRUE)
set(sodium_PKG_STATIC_LIBRARIES libsodium.a)
set(sodium_PKG_STATIC_LIBRARY_DIRS ${THIRDPARTY_INSTALL_DIR}/libsodium/lib)
set(sodium_PKG_STATIC_INCLUDE_DIRS ${THIRDPARTY_INSTALL_DIR}/libsodium/include)

# Ensure ZLIB is properly configured for fizz-config.cmake
set(ZLIB_FOUND TRUE)
set(ZLIB_INCLUDE_DIRS ${THIRDPARTY_INSTALL_DIR}/zlib/include)
set(ZLIB_LIBRARIES ${THIRDPARTY_INSTALL_DIR}/zlib/lib/libz.a)
set(ZLIB_VERSION_STRING "1.3.1")

find_package(fizz CONFIG REQUIRED)
message(STATUS "Fizz imported into superproject: ${FIZZ_INSTALL_DIR}")
