# Apache Arrow third-party integration (C++)
# Reference: https://arrow.apache.org

thirdparty_setup_directories("arrow")

list(APPEND _opt_flags
    -DCMAKE_INSTALL_PREFIX=${ARROW_INSTALL_DIR}

    -DARROW_BUILD_SHARED=OFF
    -DARROW_BUILD_STATIC=ON

    # Use system dependencies we already build
    -DARROW_DEPENDENCY_SOURCE=SYSTEM
    -DARROW_DEPENDENCY_USE_SHARED=OFF

    # Import Include files: boost abseil
    -DCMAKE_CXX_FLAGS=-I${THIRDPARTY_INSTALL_DIR}/boost/include\ -I${THIRDPARTY_INSTALL_DIR}/abseil/include
    -DCMAKE_C_FLAGS=-I${THIRDPARTY_INSTALL_DIR}/boost/include\ -I${THIRDPARTY_INSTALL_DIR}/abseil/include

    # Boost
    -DBoost_SOURCE=SYSTEM

    # Thrift
    -DThrift_SOURCE=SYSTEM

    # Snappy
    -DARROW_WITH_SNAPPY=ON
    -DARROW_SNAPPY_USE_SHARED=OFF
    -DSNAPPY_USE_STATIC_LIBS=ON
    -DSnappy_SOURCE=SYSTEM

    # Zlib
    -DARROW_WITH_ZLIB=ON
    -DZLIB_USE_STATIC_LIBS=ON
    -DZLIB_SOURCE=SYSTEM

    # Zstd
    -DARROW_WITH_ZSTD=ON
    -DARROW_ZSTD_USE_SHARED=OFF
    -DZSTD_USE_STATIC_LIBS=ON
    -DZSTD_SOURCE=SYSTEM

    # LZ4
    -DARROW_WITH_LZ4=ON
    -DARROW_WITH_LZMA=ON
    -DARROW_LZ4_USE_SHARED=OFF
    -DLZ4_USE_STATIC_LIBS=ON
    -DLZ4_SOURCE=SYSTEM

    # BZip2
    -DARROW_WITH_BZ2=ON
    -DARROW_BZ2_USE_SHARED=OFF
    -DBZIP2_USE_STATIC_LIBS=ON
    -DBZip2_SOURCE=SYSTEM

    # OpenSSL
    -DOpenSSL_SOURCE=SYSTEM

    # Protobuf
    -DARROW_PROTOBUF_USE_SHARED=OFF

    # Arrow Components
    -DARROW_ACERO=ON
    -DARROW_DATASET=ON
    -DARROW_COMPUTE=ON
    -DARROW_CSV=ON
    -DARROW_JSON=ON
    -DARROW_FLIGHT=OFF
    -DARROW_GANDIVA=ON
    -DARROW_FILESYSTEM=ON
    -DARROW_ORC=OFF
    -DARROW_WITH_RE2=ON
    -DARROW_WITH_UTF8PROC=ON
    -DARROW_USE_GLOG=ON
    -DARROW_WITH_GRPC=OFF
    -DARROW_FUZZING=OFF
    -DARROW_HDFS=ON
    -DARROW_JEMALLOC=OFF
    -DARROW_MIMALLOC=ON
    -DARROW_SUBSTRAIT=ON
    -DARROW_TENSORFLOW=ON

    # Parquet
    -DARROW_PARQUET=ON
    -DPARQUET_BUILD_EXECUTABLES=ON
    -DPARQUET_REQUIRE_ENCRYPTION=ON

    # Gandiva
    -DARROW_GANDIVA_STATIC_LIBSTDCPP=OFF

    # Arrow Build Options
    -DARROW_TESTING=OFF
    -DARROW_BUILD_TESTS=OFF
    -DARROW_BUILD_EXAMPLES=OFF
    -DARROW_BUILD_BENCHMARKS=OFF
    -DARROW_BUILD_INTEGRATION=OFF
    -DARROW_BUILD_UTILITIES=OFF
)

thirdparty_build_cmake_library("arrow"
    SOURCE_SUBDIR "cpp"
    CMAKE_ARGS ${_opt_flags}
    VALIDATION_FILES
        "${ARROW_INSTALL_DIR}/lib/libarrow.a"
        "${ARROW_INSTALL_DIR}/lib/cmake/Arrow/ArrowConfig.cmake"
)

find_package(Arrow CONFIG REQUIRED)
if(TARGET Arrow::arrow_static AND NOT TARGET Arrow::arrow)
    add_library(Arrow::arrow ALIAS Arrow::arrow_static)
endif()
message(STATUS "Arrow imported into superproject: ${ARROW_INSTALL_DIR}")
