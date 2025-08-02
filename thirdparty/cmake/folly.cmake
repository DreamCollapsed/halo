# Folly third-party integration
# Reference: https://github.com/facebook/folly/blob/main/README.md

thirdparty_check_dependencies("gflags;glog;double-conversion;libevent;openssl;zstd;lz4;snappy;boost;fmt;jemalloc;zlib;xz;bzip2;libsodium")

# Set up directories
set(FOLLY_NAME "folly")
set(FOLLY_DOWNLOAD_FILE "${THIRDPARTY_DOWNLOAD_DIR}/folly-${FOLLY_VERSION}.tar.gz")
set(FOLLY_SOURCE_DIR "${THIRDPARTY_SRC_DIR}/${FOLLY_NAME}")
set(FOLLY_BUILD_DIR "${THIRDPARTY_BUILD_DIR}/${FOLLY_NAME}")
set(FOLLY_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/${FOLLY_NAME}")

get_filename_component(FOLLY_INSTALL_DIR "${FOLLY_INSTALL_DIR}" ABSOLUTE)

# Download and extract folly
thirdparty_download_and_check("${FOLLY_URL}" "${FOLLY_DOWNLOAD_FILE}" "${FOLLY_SHA256}")
thirdparty_extract_and_rename("${FOLLY_DOWNLOAD_FILE}" "${FOLLY_SOURCE_DIR}" "${THIRDPARTY_SRC_DIR}/folly-*" )

# Update Boost version in folly-deps.cmake
file(READ "${FOLLY_SOURCE_DIR}/CMake/folly-deps.cmake" FOLLY_DEPS_CONTENT)
string(REPLACE "find_package(Boost 1.88.0 MODULE" "find_package(Boost ${BOOST_VERSION} MODULE" FOLLY_DEPS_CONTENT "${FOLLY_DEPS_CONTENT}")
file(WRITE "${FOLLY_SOURCE_DIR}/CMake/folly-deps.cmake" "${FOLLY_DEPS_CONTENT}")


thirdparty_get_optimization_flags(_opt_flags COMPONENT folly)

if(APPLE AND EXISTS "${THIRDPARTY_INSTALL_DIR}/jemalloc/include/jemalloc_prefix_compat.h")
    list(APPEND _opt_flags
        -DCMAKE_CXX_FLAGS=-I${THIRDPARTY_INSTALL_DIR}/jemalloc/include\ -include\ ${THIRDPARTY_INSTALL_DIR}/jemalloc/include/jemalloc_prefix_compat.h
    )
endif()

list(APPEND _opt_flags
    -DCMAKE_INSTALL_PREFIX=${FOLLY_INSTALL_DIR}
    
    # Disable CMP0167 to keep FindBoost.cmake available without warnings
    -DCMAKE_POLICY_DEFAULT_CMP0167=OLD

    # GLOG
    -DGLOG_LIBRARYDIR=${THIRDPARTY_INSTALL_DIR}/glog/lib
    -DGLOG_INCLUDEDIR=${THIRDPARTY_INSTALL_DIR}/glog/include
    -DGLOG_LIBRARY=${THIRDPARTY_INSTALL_DIR}/glog/lib/libglog.a
    -DGLOG_INCLUDE_DIR=${THIRDPARTY_INSTALL_DIR}/glog/include
    -DGLOG_FOUND=TRUE
    -DFOLLY_HAVE_LIBGLOG:BOOL=ON

    # Boost (MODULE mode) - support both Folly's FindBoost and system FindBoost
    -DBOOST_ROOT=${THIRDPARTY_INSTALL_DIR}/boost
    -DBOOST_INCLUDEDIR=${THIRDPARTY_INSTALL_DIR}/boost/include
    -DBOOST_LIBRARYDIR=${THIRDPARTY_INSTALL_DIR}/boost/lib
    -DFOLLY_BOOST_LINK_STATIC=ON
    -DBOOST_LINK_STATIC=ON
    -DBoost_USE_STATIC_LIBS=ON
    -DBoost_USE_MULTITHREADED=ON
    -DBoost_USE_STATIC_RUNTIME=ON
    -DBoost_NO_SYSTEM_PATHS=ON
    
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

    # --- Folly Specifics ---
    -DFOLLY_HAVE_UNALIGNED_ACCESS:BOOL=ON
    -DFOLLY_USE_SYMBOLIZER:BOOL=ON
    -DFOLLY_HAVE_BACKTRACE:BOOL=ON   
)

thirdparty_cmake_configure("${FOLLY_SOURCE_DIR}" "${FOLLY_BUILD_DIR}"
    FORCE_CONFIGURE
    VALIDATION_FILES
        "${FOLLY_BUILD_DIR}/CMakeCache.txt"
        "${FOLLY_BUILD_DIR}/Makefile"
    CMAKE_ARGS
        ${_opt_flags}
)

thirdparty_cmake_install("${FOLLY_BUILD_DIR}" "${FOLLY_INSTALL_DIR}"
    VALIDATION_FILES
        "${FOLLY_INSTALL_DIR}/lib/libfolly.a"
        "${FOLLY_INSTALL_DIR}/include/folly/folly-config.h"
)

thirdparty_safe_set_parent_scope(FOLLY_INSTALL_DIR "${FOLLY_INSTALL_DIR}")
set(Folly_DIR "${FOLLY_INSTALL_DIR}/lib/cmake/folly" CACHE PATH "Path to installed Folly cmake config" FORCE)

if(EXISTS "${FOLLY_INSTALL_DIR}/lib/cmake/folly/folly-config.cmake")
    find_package(Folly REQUIRED CONFIG QUIET)
    message(STATUS "Folly found and imported: ${FOLLY_INSTALL_DIR}")
else()
    message(WARNING "Folly cmake config not found at ${FOLLY_INSTALL_DIR}")
endif()
