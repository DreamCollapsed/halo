# Folly third-party integration
# Reference: https://github.com/facebook/folly/blob/main/README.md

thirdparty_build_cmake_library("folly"
    FILE_REPLACEMENTS
        # Fix Boost version dependency
        "CMake/folly-deps.cmake"
        "find_package(Boost 1.88.0 MODULE"
        "find_package(Boost ${BOOST_VERSION} MODULE"
    CMAKE_ARGS
        -DCMAKE_POLICY_DEFAULT_CMP0167=OLD

        # GLOG
        -DGLOG_LIBRARYDIR=${THIRDPARTY_INSTALL_DIR}/glog/lib
        -DGLOG_INCLUDEDIR=${THIRDPARTY_INSTALL_DIR}/glog/include
        -DGLOG_LIBRARY=${THIRDPARTY_INSTALL_DIR}/glog/lib/libglog.a
        -DGLOG_INCLUDE_DIR=${THIRDPARTY_INSTALL_DIR}/glog/include
        -DGLOG_FOUND=TRUE
        -DFOLLY_HAVE_LIBGLOG:BOOL=ON

        # Boost
        -DFOLLY_BOOST_LINK_STATIC=ON
        
        # FASTFLOAT
        -DFASTFLOAT_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/fast-float/include

        # DOUBLE_CONVERSION
        -DDOUBLE_CONVERSION_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/double-conversion/include
        -DDOUBLE_CONVERSION_LIBRARY:FILEPATH=${THIRDPARTY_INSTALL_DIR}/double-conversion/lib/libdouble-conversion.a

        # LIBEVENT
        -DLIBEVENT_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/libevent/include
        -DLIBEVENT_LIB:FILEPATH=${THIRDPARTY_INSTALL_DIR}/libevent/lib/libevent.a

        # OpenSSL - ensure folly uses project OpenSSL not system OpenSSL
        -DOPENSSL_ROOT_DIR=${THIRDPARTY_INSTALL_DIR}/openssl
        -DOPENSSL_INCLUDE_DIR=${THIRDPARTY_INSTALL_DIR}/openssl/include
        -DOPENSSL_SSL_LIBRARY=${THIRDPARTY_INSTALL_DIR}/openssl/lib/libssl.a
        -DOPENSSL_CRYPTO_LIBRARY=${THIRDPARTY_INSTALL_DIR}/openssl/lib/libcrypto.a

        # Jemalloc
        -DJEMALLOC_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/jemalloc/include
        -DJEMALLOC_LIBRARY:FILEPATH=${THIRDPARTY_INSTALL_DIR}/jemalloc/lib/libjemalloc_pic.a
        -DCMAKE_SHARED_LINKER_FLAGS=-L${THIRDPARTY_INSTALL_DIR}/jemalloc/lib\ -ljemalloc_pic
        -DCMAKE_EXE_LINKER_FLAGS=-L${THIRDPARTY_INSTALL_DIR}/jemalloc/lib\ -ljemalloc_pic
        -DFOLLY_USE_JEMALLOC:BOOL=ON

        # ZLIB
        -DZLIB_ROOT=${THIRDPARTY_INSTALL_DIR}/zlib
        -DZLIB_INCLUDE_DIR=${THIRDPARTY_INSTALL_DIR}/zlib/include
        -DZLIB_LIBRARY=${THIRDPARTY_INSTALL_DIR}/zlib/lib/libz.a
        
        # BZIP2
        -DBZIP2_INCLUDE_DIR=${THIRDPARTY_INSTALL_DIR}/bzip2/include
        -DBZIP2_INCLUDE_DIRS=${THIRDPARTY_INSTALL_DIR}/bzip2/include
        -DBZIP2_LIBRARY=${THIRDPARTY_INSTALL_DIR}/bzip2/lib/libbz2.a
        -DBZIP2_LIBRARIES=${THIRDPARTY_INSTALL_DIR}/bzip2/lib/libbz2.a
        
        # XZ/LZMA
        -DLIBLZMA_INCLUDE_DIR=${THIRDPARTY_INSTALL_DIR}/xz/include
        -DLIBLZMA_LIBRARY=${THIRDPARTY_INSTALL_DIR}/xz/lib/liblzma.a

        # LZ4 - ensure folly uses project LZ4 not system LZ4
        -DLZ4_ROOT=${THIRDPARTY_INSTALL_DIR}/lz4
        -DLZ4_INCLUDE_DIR=${THIRDPARTY_INSTALL_DIR}/lz4/include
        -DLZ4_LIBRARY=${THIRDPARTY_INSTALL_DIR}/lz4/lib/liblz4.a
        -DLZ4_LIBRARY_RELEASE=${THIRDPARTY_INSTALL_DIR}/lz4/lib/liblz4.a
        
        # ZSTD - ensure folly uses project ZSTD not system ZSTD
        -DZSTD_ROOT=${THIRDPARTY_INSTALL_DIR}/zstd
        -DZSTD_INCLUDE_DIR=${THIRDPARTY_INSTALL_DIR}/zstd/include
        -DZSTD_LIBRARY=${THIRDPARTY_INSTALL_DIR}/zstd/lib/libzstd.a
        -DZSTD_LIBRARY_RELEASE=${THIRDPARTY_INSTALL_DIR}/zstd/lib/libzstd.a

        # LIBSODIUM
        -DLIBSODIUM_INCLUDE_DIR=${THIRDPARTY_INSTALL_DIR}/libsodium/include
        -DLIBSODIUM_LIBRARY=${THIRDPARTY_INSTALL_DIR}/libsodium/lib/libsodium.a

        # GFLAGS
        -DFOLLY_HAVE_LIBGFLAGS:BOOL=ON

        # SNAPPY
        -DSNAPPY_LIBRARY=${THIRDPARTY_INSTALL_DIR}/snappy/lib/libsnappy.a
        -DSNAPPY_INCLUDE_DIR=${THIRDPARTY_INSTALL_DIR}/snappy/include

        # JEMALLOC
        -DCMAKE_CXX_FLAGS=-I${THIRDPARTY_INSTALL_DIR}/jemalloc/include\ -include\ ${THIRDPARTY_INSTALL_DIR}/jemalloc/include/jemalloc_prefix_compat.h

        # --- Folly Specifics ---
        -DFOLLY_HAVE_UNALIGNED_ACCESS:BOOL=ON
        -DFOLLY_USE_SYMBOLIZER:BOOL=ON
        -DFOLLY_HAVE_BACKTRACE:BOOL=ON
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/folly/lib/libfolly.a"
        "${THIRDPARTY_INSTALL_DIR}/folly/include/folly/folly-config.h"
)

if(EXISTS "${FOLLY_INSTALL_DIR}/lib/cmake/folly/folly-config.cmake")
    file(READ "${FOLLY_INSTALL_DIR}/lib/cmake/folly/folly-config.cmake" folly_config_content)
    string(REPLACE "find_dependency(Boost 1.51.0 MODULE" "find_dependency(Boost ${BOOST_VERSION} MODULE" folly_config_content "${folly_config_content}")
    file(WRITE "${FOLLY_INSTALL_DIR}/lib/cmake/folly/folly-config.cmake" "${folly_config_content}")

    find_package(Folly CONFIG REQUIRED)
    
    # Some dependents (fizz/wangle) ask for "folly" in lowercase via find_dependency
    # Populate lowercase cache too to avoid re-search and negative cache writes
    find_package(folly CONFIG REQUIRED)
    message(STATUS "Folly imported into superproject: ${FOLLY_INSTALL_DIR}")
else()
    message(FATAL_ERROR "Folly cmake config not found at ${FOLLY_INSTALL_DIR}")
endif()
