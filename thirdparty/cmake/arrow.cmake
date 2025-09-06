# Apache Arrow third-party integration (C++)
# Reference: https://arrow.apache.org

thirdparty_setup_directories("arrow")

list(APPEND _opt_flags
    -DCMAKE_INSTALL_PREFIX=${ARROW_INSTALL_DIR}

    -DARROW_BUILD_SHARED=OFF
    -DARROW_BUILD_STATIC=ON
    -DARROW_CXX_FLAGS_RELEASE=-O3

    -DARROW_TESTING=ON
    -DARROW_BUILD_TESTS=OFF
    -DARROW_BUILD_EXAMPLES=OFF
    -DARROW_BUILD_BENCHMARKS=OFF
    -DARROW_BUILD_INTEGRATION=ON
    -DARROW_BUILD_UTILITIES=ON

    # Use system dependencies we already build
    -DARROW_DEPENDENCY_SOURCE=SYSTEM
    -DARROW_DEPENDENCY_USE_SHARED=OFF

    # Import Include files: boost abseil + jemalloc compatibility
    -DCMAKE_CXX_FLAGS=-I${THIRDPARTY_INSTALL_DIR}/boost/include\ -I${THIRDPARTY_INSTALL_DIR}/abseil/include\ -include\ ${THIRDPARTY_INSTALL_DIR}/jemalloc/include/jemalloc_prefix_compat.h
    -DCMAKE_C_FLAGS=-I${THIRDPARTY_INSTALL_DIR}/boost/include\ -I${THIRDPARTY_INSTALL_DIR}/abseil/include\ -include\ ${THIRDPARTY_INSTALL_DIR}/jemalloc/include/jemalloc_prefix_compat.h

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
    -DOPENSSL_ROOT_DIR=${THIRDPARTY_INSTALL_DIR}/openssl
    -DOPENSSL_INCLUDE_DIR=${THIRDPARTY_INSTALL_DIR}/openssl/include
    -DOPENSSL_SSL_LIBRARY=${THIRDPARTY_INSTALL_DIR}/openssl/lib/libssl.a
    -DOPENSSL_CRYPTO_LIBRARY=${THIRDPARTY_INSTALL_DIR}/openssl/lib/libcrypto.a

    # Jemalloc
    -DARROW_JEMALLOC=ON
    -DARROW_JEMALLOC_USE_SHARED=OFF
    -Djemalloc_SOURCE=SYSTEM
    -Djemalloc_ROOT=${THIRDPARTY_INSTALL_DIR}/jemalloc

    # Protobuf
    -DARROW_PROTOBUF_USE_SHARED=OFF

    # Arrow Components
    -DARROW_ACERO=ON
    -DARROW_DATASET=ON
    -DARROW_COMPUTE=ON
    -DARROW_CSV=ON
    -DARROW_JSON=ON
    -DARROW_FILESYSTEM=ON
    -DARROW_ORC=OFF
    -DARROW_WITH_RE2=ON
    -DARROW_WITH_UTF8PROC=ON
    -DARROW_USE_GLOG=ON
    -DARROW_WITH_GRPC=ON
    -DARROW_FUZZING=OFF
    -DARROW_HDFS=ON
    -DARROW_MIMALLOC=OFF
    -DARROW_SUBSTRAIT=ON
    -DARROW_TENSORFLOW=ON

    # Parquet
    -DARROW_PARQUET=ON
    -DPARQUET_BUILD_EXECUTABLES=ON
    -DPARQUET_REQUIRE_ENCRYPTION=ON

    # Gandiva
    -DARROW_GANDIVA=ON
    -DARROW_GANDIVA_STATIC_LIBSTDCPP=ON

    # Flight
    -DARROW_FLIGHT=ON
    -DARROW_FLIGHT_SQL=ON
    -DARROW_FLIGHT_SQL_ODBC=ON
)

thirdparty_build_cmake_library("arrow"
    SOURCE_SUBDIR "cpp"
    CMAKE_ARGS ${_opt_flags}
    FILE_REPLACEMENTS
    # Fix C++23 derived-to-base pointer conversion at BackpressureController creation
    # (AsofJoinNode* to ExecNode*). Use an explicit cast on the call site to avoid
    # incomplete-type conversion errors when AsofJoinNode is forward-declared.
    "cpp/src/arrow/acero/asof_join_node.cc"
    "/*output=*/asof_node"
    "/*output=*/(ExecNode*)asof_node"
    VALIDATION_FILES
        "${ARROW_INSTALL_DIR}/lib/libarrow.a"
        "${ARROW_INSTALL_DIR}/lib/cmake/Arrow/ArrowConfig.cmake"
)

find_package(Arrow CONFIG REQUIRED)
if(TARGET Arrow::arrow_static AND NOT TARGET Arrow::arrow)
    add_library(Arrow::arrow ALIAS Arrow::arrow_static)
endif()
message(STATUS "Arrow imported into superproject: ${ARROW_INSTALL_DIR}")

find_package(ArrowAcero CONFIG REQUIRED)
if(TARGET ArrowAcero::arrow_acero_static AND NOT TARGET ArrowAcero::arrow_acero)
    add_library(ArrowAcero::arrow_acero ALIAS ArrowAcero::arrow_acero_static)
endif()
message(STATUS "ArrowAcero imported into superproject: ${ARROW_INSTALL_DIR}")

find_package(ArrowCompute CONFIG REQUIRED)
if(TARGET ArrowCompute::arrow_compute_static AND NOT TARGET ArrowCompute::arrow_compute)
    add_library(ArrowCompute::arrow_compute ALIAS ArrowCompute::arrow_compute_static)
endif()
message(STATUS "ArrowCompute imported into superproject: ${ARROW_INSTALL_DIR}")

find_package(ArrowDataset CONFIG REQUIRED)
if(TARGET ArrowDataset::arrow_dataset_static AND NOT TARGET ArrowDataset::arrow_dataset)
    add_library(ArrowDataset::arrow_dataset ALIAS ArrowDataset::arrow_dataset_static)
endif()
message(STATUS "ArrowDataset imported into superproject: ${ARROW_INSTALL_DIR}")

find_package(ArrowFlight CONFIG REQUIRED)
if(TARGET ArrowFlight::arrow_flight_static AND NOT TARGET ArrowFlight::arrow_flight)
    add_library(ArrowFlight::arrow_flight ALIAS ArrowFlight::arrow_flight_static)
endif()
message(STATUS "ArrowFlight imported into superproject: ${ARROW_INSTALL_DIR}")

find_package(ArrowFlightSql CONFIG REQUIRED)
if(TARGET ArrowFlightSql::arrow_flight_sql_static AND NOT TARGET ArrowFlightSql::arrow_flight_sql)
    add_library(ArrowFlightSql::arrow_flight_sql ALIAS ArrowFlightSql::arrow_flight_sql_static)
endif()
message(STATUS "ArrowFlightSql imported into superproject: ${ARROW_INSTALL_DIR}")

find_package(ArrowSubstrait CONFIG REQUIRED)
if(TARGET ArrowSubstrait::arrow_substrait_static AND NOT TARGET ArrowSubstrait::arrow_substrait)
    add_library(ArrowSubstrait::arrow_substrait ALIAS ArrowSubstrait::arrow_substrait_static)
endif()
message(STATUS "ArrowSubstrait imported into superproject: ${ARROW_INSTALL_DIR}")

find_package(Gandiva CONFIG REQUIRED)
if(TARGET Gandiva::gandiva_static AND NOT TARGET Gandiva::gandiva)
    add_library(Gandiva::gandiva ALIAS Gandiva::gandiva_static)
endif()
message(STATUS "Gandiva imported into superproject: ${ARROW_INSTALL_DIR}")

find_package(Parquet CONFIG REQUIRED)
if(TARGET Parquet::parquet_static AND NOT TARGET Parquet::parquet)
    add_library(Parquet::parquet ALIAS Parquet::parquet_static)
endif()
message(STATUS "Parquet imported into superproject: ${ARROW_INSTALL_DIR}")
