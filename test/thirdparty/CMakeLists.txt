# Third-party libraries integration tests

# Abseil integration test
add_module_test(thirdparty_abseil
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_abseil_integration.cpp"
    LABELS
        abseil
        thirdparty
        integration
    TIMEOUT 30
)

# Boost integration test
add_module_test(thirdparty_boost
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_boost_integration.cpp"
    LABELS
        boost
        thirdparty
        integration
    TIMEOUT 30
)

# Bison integration test
add_module_test(thirdparty_bison
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_bison_integration.cpp"
    LABELS
        bison
        parser
        build-tools
        thirdparty
        integration
    TIMEOUT 30
)

# Flex integration test
add_module_test(thirdparty_flex
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_flex_integration.cpp"
    LABELS
        flex
        lexer
        build-tools
        thirdparty
        integration
    TIMEOUT 30
)

# GTest/GMock integration test
add_module_test(thirdparty_gtest
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_gtest_integration.cpp"
    LABELS
        gtest
        gmock
        thirdparty
        integration
    TIMEOUT 30
)

# Combined integration test (Abseil + GTest/GMock)
add_module_test(thirdparty_combined
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_combined_integration.cpp"
    LABELS
        combined
        thirdparty
        integration
    TIMEOUT 30
    PERFORMANCE
)

# gflags integration test
add_module_test(thirdparty_gflags
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_gflags_integration.cpp"
    LABELS
        gflags
        thirdparty
        integration
    TIMEOUT 30
)

# glog integration test
add_module_test(thirdparty_glog
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_glog_integration.cpp"
    LABELS
        glog
        thirdparty
        integration
    TIMEOUT 30
)

# double-conversion integration test
add_module_test(thirdparty_double_conversion
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_double_conversion_integration.cpp"
    LABELS
        double-conversion
        thirdparty
        integration
    TIMEOUT 30
)

# fast-float integration test
add_module_test(thirdparty_fast_float
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_fast_float_integration.cpp"
    LABELS
        fast-float
        thirdparty
        integration
    TIMEOUT 30
)

# fmt integration test
add_module_test(thirdparty_fmt
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_fmt_integration.cpp"
    LABELS
        fmt
        thirdparty
        integration
    TIMEOUT 30
)

# zlib integration test
add_module_test(thirdparty_zlib
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_zlib_integration.cpp"
    LABELS
        zlib
        compression
        thirdparty
        integration
    TIMEOUT 30
)

# zstd integration test
add_module_test(thirdparty_zstd
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_zstd_integration.cpp"
    LABELS
        zstd
        thirdparty
        integration
    TIMEOUT 30
)

# lz4 integration test
add_module_test(thirdparty_lz4
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_lz4_integration.cpp"
    LABELS
        lz4
        thirdparty
        integration
    TIMEOUT 30
)

# jemalloc comprehensive integration test
add_module_test(thirdparty_jemalloc_comprehensive
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_jemalloc_comprehensive.cpp"
    LABELS
        jemalloc
        comprehensive
        drop-in
        thirdparty
        integration
    TIMEOUT 60
)

# lz4-zstd integration test
add_module_test(thirdparty_lz4_zstd
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_lz4_zstd_integration.cpp"
    LABELS
        lz4
        zstd
        dictionary
        integration
        thirdparty
    TIMEOUT 30
)

# snappy integration test
add_module_test(thirdparty_snappy
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_snappy_integration.cpp"
    LABELS
        snappy
        thirdparty
        integration
    TIMEOUT 30
)

# xxhash integration test
add_module_test(thirdparty_xxhash
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_xxhash_integration.cpp"
    LABELS
        xxhash
        thirdparty
        integration
    TIMEOUT 30
)

# faiss integration test
add_module_test(thirdparty_faiss
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_faiss_integration.cpp"
    LABELS
        faiss
        thirdparty
        integration
    TIMEOUT 30
)

# fizz integration test
add_module_test(thirdparty_fizz
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_fizz_integration.cpp"
    LABELS
        fizz
        tls
        thirdparty
        integration
    TIMEOUT 30
)

# OpenSSL integration test
add_module_test(thirdparty_openssl
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_openssl_integration.cpp"
    LABELS
        openssl
        ssl
        crypto
        thirdparty
        integration
    TIMEOUT 30
)

# libevent integration test
add_module_test(thirdparty_libevent
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_libevent_integration.cpp"
    LABELS
        libevent
        event
        http
        thirdparty
        integration
    TIMEOUT 30
)

# Folly integration test
add_module_test(thirdparty_folly
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_folly_integration.cpp"
    LABELS
        folly
        fbstring
        thirdparty
        integration
    TIMEOUT 30
)

# XZ integration test
add_module_test(thirdparty_xz
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_xz_integration.cpp"
    LABELS
        xz
        lzma
        compression
        thirdparty
        integration
    TIMEOUT 30
)

# ICU4C integration test
add_module_test(thirdparty_icu4c
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_icu4c_integration.cpp"
    LABELS
        icu4c
        unicode
        locale
        thirdparty
        integration
    TIMEOUT 30
)

# bzip2 integration test
add_module_test(thirdparty_bzip2
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_bzip2_integration.cpp"
    LABELS
        bzip2
        compression
        thirdparty
        integration
    TIMEOUT 30
)

# libsodium integration test
add_module_test(thirdparty_libsodium
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_libsodium_integration.cpp"
    LABELS
        libsodium
        crypto
        encryption
        security
        thirdparty
        integration
    TIMEOUT 30
)

# libstemmer integration test
add_module_test(thirdparty_libstemmer
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_libstemmer_integration.cpp"
    LABELS
        libstemmer
        nlp
        stemming
        text-processing
        thirdparty
        integration
    TIMEOUT 30
)

# protobuf integration test
add_module_test(thirdparty_protobuf
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_protobuf_integration.cpp"
    LABELS
        protobuf
        serialization
        rpc
        data-formats
        thirdparty
        integration
    TIMEOUT 30
)

# wangle integration test
add_module_test(thirdparty_wangle
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_wangle_integration.cpp"
    LABELS
        wangle
        networking
        pipeline
        service
        thirdparty
        integration
    TIMEOUT 30
)

# mvfst integration test
add_module_test(thirdparty_mvfst
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_mvfst_integration.cpp"
    LABELS
        mvfst
        quic
        networking
        thirdparty
        integration
    TIMEOUT 30
)

# Arrow integration test
add_module_test(thirdparty_arrow
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_arrow_integration.cpp"
    CUSTOM_TARGETS halo_thirdparty_with_thrift
    LABELS
        arrow
        columnar
        thirdparty
        integration
    TIMEOUT 30
)

# Arrow extended components test (json, compute, dataset, acero, flight ...)
add_module_test(thirdparty_arrow_extended
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_arrow_extended.cpp"
    CUSTOM_TARGETS halo_thirdparty_with_thrift
    LABELS
        arrow
        extended
        thirdparty
        integration
    TIMEOUT 60
)

# xsimd integration test
add_module_test(thirdparty_xsimd
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_xsimd_integration.cpp"
    LABELS
        xsimd
        simd
        thirdparty
        integration
    TIMEOUT 30
)

# xtl integration test
add_module_test(thirdparty_xtl
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_xtl_integration.cpp"
    LABELS
        xtl
        utilities
        thirdparty
        integration
    TIMEOUT 30
)

# rapidjson integration test
add_module_test(thirdparty_rapidjson
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_rapidjson_integration.cpp"
    LABELS
        rapidjson
        json
        thirdparty
        integration
    TIMEOUT 30
)

# re2 integration test
add_module_test(thirdparty_re2
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_re2_integration.cpp"
    LABELS
        re2
        regex
        thirdparty
        integration
    TIMEOUT 30
)

# utf8proc integration test
add_module_test(thirdparty_utf8proc
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_utf8proc_integration.cpp"
    LABELS
        utf8proc
        unicode
        normalization
        thirdparty
        integration
    TIMEOUT 30
)

# gRPC integration test
add_module_test(thirdparty_grpc
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_grpc_integration.cpp"
    LABELS
        grpc
        thirdparty
        integration
    TIMEOUT 30
)

# c-ares integration test
add_module_test(thirdparty_cares
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_cares_integration.cpp"
    LABELS
        cares
        dns
        thirdparty
        integration
    TIMEOUT 30
)

# GEOS integration test
add_module_test(thirdparty_geos
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_geos_integration.cpp"
    LABELS
        geos
        geometry
        spatial
        thirdparty
        integration
    TIMEOUT 30
)

# simdjson integration test
add_module_test(thirdparty_simdjson
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_simdjson_integration.cpp"
    LABELS
        simdjson
        json
        parser
        thirdparty
        integration
    TIMEOUT 30
)

# fbthrift integration test
add_module_test(thirdparty_fbthrift
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_fbthrift_integration.cpp"
    CUSTOM_TARGETS halo_thirdparty_with_fbthrift
    LABELS
        fbthrift
        thriftcpp2
        rpc
        thirdparty
        integration
    TIMEOUT 30
)

# thrift integration test
add_module_test(thirdparty_thrift
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_thrift_integration.cpp"
    CUSTOM_TARGETS halo_thirdparty_with_thrift
    LABELS
        thrift
        serialization
        rpc
        data-formats
        thirdparty
        integration
    TIMEOUT 30
)

# Velox integration test (basic API)
add_module_test(velox_integration
    TEST_SOURCES
        "${CMAKE_CURRENT_SOURCE_DIR}/velox_test_env.cpp"
        "${CMAKE_CURRENT_SOURCE_DIR}/test_velox_integration.cpp"
    CUSTOM_TARGETS
        halo_thirdparty_with_thrift
        halo_velox_unified
    LABELS
        velox
        query-engine
        columnar
        thirdparty
        integration
)

# Velox vector tests (vectors, memory, calculations)
add_module_test(velox_vectors
    TEST_SOURCES
        "${CMAKE_CURRENT_SOURCE_DIR}/velox_test_env.cpp"
        "${CMAKE_CURRENT_SOURCE_DIR}/test_velox_vectors.cpp"
    CUSTOM_TARGETS
        halo_thirdparty_with_thrift
        halo_velox_unified
    LABELS
        velox
        vectors
        thirdparty
        integration
)

# Velox pipeline tests (plan execution, joins, aggregations)
add_module_test(velox_pipeline
    TEST_SOURCES
        "${CMAKE_CURRENT_SOURCE_DIR}/velox_test_env.cpp"
        "${CMAKE_CURRENT_SOURCE_DIR}/test_velox_pipeline.cpp"
    CUSTOM_TARGETS
        halo_thirdparty_with_thrift
        halo_velox_unified
    LABELS
        velox
        pipeline
        execution
        thirdparty
        integration
)

# OpenMP integration test
add_module_test(thirdparty_openmp
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_openmp_integration.cpp"
    LABELS
        openmp
        llvm-project
        parallel
        thirdparty
        integration
)

# libunwind integration test
add_module_test(thirdparty_libunwind
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_libunwind_integration.cpp"
    LABELS
        libunwind
        llvm-project
        debugging
        thirdparty
        integration
)
