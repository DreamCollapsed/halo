# Folly third-party integration
# Reference: https://github.com/facebook/folly/blob/main/README.md

# jemalloc configuration: platform-specific approach
if(APPLE)
    # On macOS we need to remap expected (non-je_) allocator symbols to jemalloc's je_ prefixed ones.
    # Include both the directory and the compatibility header for symbol remapping.
    set(_FOLLY_JEMALLOC_CXX_FLAGS "-I${THIRDPARTY_INSTALL_DIR}/jemalloc/include -include ${THIRDPARTY_INSTALL_DIR}/jemalloc/include/jemalloc_prefix_compat.h")
    set(_FOLLY_USE_JEMALLOC ON)
    set(_FOLLY_EXTRA_C_FLAGS "")
    # Use safe flag combination utility to avoid truncation issues
    thirdparty_combine_flags(_FOLLY_CXX_FLAGS FRAGMENTS "${HALO_CMAKE_CXX_FLAGS_BASE}" "${_FOLLY_JEMALLOC_CXX_FLAGS}")
    thirdparty_combine_flags(_FOLLY_EXE_LINKER_FLAGS FRAGMENTS "${HALO_CMAKE_EXE_LINKER_FLAGS_BASE}" "-L${THIRDPARTY_INSTALL_DIR}/jemalloc/lib" "-ljemalloc_pic")
    thirdparty_combine_flags(_FOLLY_SHARED_LINKER_FLAGS FRAGMENTS "${HALO_CMAKE_SHARED_LINKER_FLAGS_BASE}" "-L${THIRDPARTY_INSTALL_DIR}/jemalloc/lib" "-ljemalloc_pic")
else()
    # On Linux, avoid including jemalloc headers during compilation to prevent posix_memalign exception spec conflicts
    # Disable folly's jemalloc integration - jemalloc will work as runtime replacement via linker flags
    set(_FOLLY_JEMALLOC_CXX_FLAGS "")
    set(_FOLLY_USE_JEMALLOC OFF)
    # Use lld on Linux to fix library format compatibility issues
    set(_FOLLY_EXTRA_C_FLAGS "")
    # Use safe flag combination utility
    thirdparty_combine_flags(_FOLLY_CXX_FLAGS FRAGMENTS "${HALO_CMAKE_CXX_FLAGS_BASE}" "")
    thirdparty_combine_flags(_FOLLY_EXE_LINKER_FLAGS FRAGMENTS "${HALO_CMAKE_EXE_LINKER_FLAGS_BASE}")
    thirdparty_combine_flags(_FOLLY_SHARED_LINKER_FLAGS FRAGMENTS "${HALO_CMAKE_SHARED_LINKER_FLAGS_BASE}")
endif()

thirdparty_build_cmake_library("folly"
    CMAKE_ARGS
        -DCMAKE_POLICY_DEFAULT_CMP0167=OLD

        # Platform-specific compiler and linker settings using base + folly-specific flags
        -DCMAKE_CXX_FLAGS=${_FOLLY_CXX_FLAGS}
        -DCMAKE_EXE_LINKER_FLAGS=${_FOLLY_EXE_LINKER_FLAGS}
        -DCMAKE_SHARED_LINKER_FLAGS=${_FOLLY_SHARED_LINKER_FLAGS}
        -DCMAKE_C_FLAGS=${_FOLLY_EXTRA_C_FLAGS}

        # GLOG
        -DGLOG_LIBRARYDIR=${THIRDPARTY_INSTALL_DIR}/glog/lib
        -DGLOG_INCLUDEDIR=${THIRDPARTY_INSTALL_DIR}/glog/include
        -DGLOG_LIBRARY=${THIRDPARTY_INSTALL_DIR}/glog/lib/libglog.a
        -DGLOG_INCLUDE_DIR=${THIRDPARTY_INSTALL_DIR}/glog/include
        -DGLOG_FOUND=TRUE
        -DFOLLY_HAVE_LIBGLOG:BOOL=ON
        -DFOLLY_HAVE_INT128_T:BOOL=ON

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
        -DFOLLY_USE_JEMALLOC:BOOL=${_FOLLY_USE_JEMALLOC}

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

        # --- Folly Specifics ---
        -DFOLLY_HAVE_UNALIGNED_ACCESS:BOOL=ON
        -DFOLLY_USE_SYMBOLIZER:BOOL=ON
        -DFOLLY_HAVE_BACKTRACE:BOOL=ON
    FILE_REPLACEMENTS
        "folly/hash/Checksum.cpp"
        "#include <folly/hash/Checksum.h>"
        "#include <folly/hash/Checksum.h>\n#include <stdexcept>"
        "folly/lang/Exception.cpp"
        "std::unexpected_handler unexpectedHandler;"
        "// std::unexpected_handler removed in C++17, use terminate_handler instead\nstd::terminate_handler unexpectedHandler;"
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/folly/lib/libfolly.a"
        "${THIRDPARTY_INSTALL_DIR}/folly/include/folly/folly-config.h"
)

if(EXISTS "${THIRDPARTY_INSTALL_DIR}/folly/lib/cmake/folly/folly-config.cmake")
    halo_find_package(Folly CONFIG QUIET REQUIRED)
    
    # Some dependents (fizz/wangle) ask for "folly" in lowercase via find_dependency
    # Populate lowercase cache too to avoid re-search and negative cache writes
    halo_find_package(folly CONFIG QUIET REQUIRED)
    
    thirdparty_map_imported_config(Folly::folly)
else()
    message(FATAL_ERROR "Folly cmake config not found at ${THIRDPARTY_INSTALL_DIR}/folly")
endif()
