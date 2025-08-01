# Third-party libraries integration tests

# Abseil integration test
add_module_test(thirdparty_abseil
    "${CMAKE_CURRENT_SOURCE_DIR}/test_abseil_integration.cpp"
    LABELS
        abseil
        thirdparty
        integration
    TIMEOUT 30
)

# Boost integration test
add_module_test(thirdparty_boost
    "${CMAKE_CURRENT_SOURCE_DIR}/test_boost_integration.cpp"
    LABELS
        boost
        thirdparty
        integration
    TIMEOUT 30
)

# Bison integration test
add_module_test(thirdparty_bison
    "${CMAKE_CURRENT_SOURCE_DIR}/test_bison_integration.cpp"
    LABELS
        bison
        parser
        build-tools
        thirdparty
        integration
    TIMEOUT 30
)
if(DEFINED BISON_EXECUTABLE_PATH)
    target_compile_definitions(test_thirdparty_bison PRIVATE 
        BISON_EXECUTABLE_PATH="${BISON_EXECUTABLE_PATH}")
endif()

# Flex integration test
add_module_test(thirdparty_flex
    "${CMAKE_CURRENT_SOURCE_DIR}/test_flex_integration.cpp"
    LABELS
        flex
        lexer
        build-tools
        thirdparty
        integration
    TIMEOUT 30
)
if(DEFINED FLEX_EXECUTABLE_PATH)
    target_compile_definitions(test_thirdparty_flex PRIVATE 
        FLEX_EXECUTABLE_PATH="${FLEX_EXECUTABLE_PATH}")
endif()

# GTest/GMock integration test
add_module_test(thirdparty_gtest
    "${CMAKE_CURRENT_SOURCE_DIR}/test_gtest_integration.cpp"
    LABELS
        gtest
        gmock
        thirdparty
        integration
    TIMEOUT 30
)

# Combined integration test (Abseil + GTest/GMock)
add_module_test(thirdparty_combined
    "${CMAKE_CURRENT_SOURCE_DIR}/test_combined_integration.cpp"
    LABELS
        combined
        thirdparty
        integration
    TIMEOUT 30
    PERFORMANCE
)

# gflags integration test
add_module_test(thirdparty_gflags
    "${CMAKE_CURRENT_SOURCE_DIR}/test_gflags_integration.cpp"
    LABELS
        gflags
        thirdparty
        integration
    TIMEOUT 30
)

# glog integration test
add_module_test(thirdparty_glog
    "${CMAKE_CURRENT_SOURCE_DIR}/test_glog_integration.cpp"
    LABELS
        glog
        thirdparty
        integration
    TIMEOUT 30
)

# double-conversion integration test
add_module_test(thirdparty_double_conversion
    "${CMAKE_CURRENT_SOURCE_DIR}/test_double_conversion_integration.cpp"
    LABELS
        double-conversion
        thirdparty
        integration
    TIMEOUT 30
)

# fast-float integration test
add_module_test(thirdparty_fast_float
    "${CMAKE_CURRENT_SOURCE_DIR}/test_fast_float_integration.cpp"
    LABELS
        fast-float
        thirdparty
        integration
    TIMEOUT 30
)

# fmt integration test
add_module_test(thirdparty_fmt
    "${CMAKE_CURRENT_SOURCE_DIR}/test_fmt_integration.cpp"
    LABELS
        fmt
        thirdparty
        integration
    TIMEOUT 30
)

# zlib integration test
add_module_test(thirdparty_zlib
    "${CMAKE_CURRENT_SOURCE_DIR}/test_zlib_integration.cpp"
    LABELS
        zlib
        compression
        thirdparty
        integration
    TIMEOUT 30
)

# zstd integration test
add_module_test(thirdparty_zstd
    "${CMAKE_CURRENT_SOURCE_DIR}/test_zstd_integration.cpp"
    LABELS
        zstd
        thirdparty
        integration
    TIMEOUT 30
)

# lz4 integration test
add_module_test(thirdparty_lz4
    "${CMAKE_CURRENT_SOURCE_DIR}/test_lz4_integration.cpp"
    LABELS
        lz4
        thirdparty
        integration
    TIMEOUT 30
)

# jemalloc comprehensive integration test
add_module_test(thirdparty_jemalloc_comprehensive
    "${CMAKE_CURRENT_SOURCE_DIR}/test_jemalloc_comprehensive.cpp"
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
    "${CMAKE_CURRENT_SOURCE_DIR}/test_lz4_zstd_integration.cpp"
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
    "${CMAKE_CURRENT_SOURCE_DIR}/test_snappy_integration.cpp"
    LABELS
        snappy
        thirdparty
        integration
    TIMEOUT 30
)

# xxhash integration test
add_module_test(thirdparty_xxhash
    "${CMAKE_CURRENT_SOURCE_DIR}/test_xxhash_integration.cpp"
    LABELS
        xxhash
        thirdparty
        integration
    TIMEOUT 30
)

# OpenSSL integration test
add_module_test(thirdparty_openssl
    "${CMAKE_CURRENT_SOURCE_DIR}/test_openssl_integration.cpp"
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
    "${CMAKE_CURRENT_SOURCE_DIR}/test_libevent_integration.cpp"
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
    "${CMAKE_CURRENT_SOURCE_DIR}/test_folly_integration.cpp"
    LABELS
        folly
        fbstring
        thirdparty
        integration
    TIMEOUT 30
)

# XZ integration test
add_module_test(thirdparty_xz
    "${CMAKE_CURRENT_SOURCE_DIR}/test_xz_integration.cpp"
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
    "${CMAKE_CURRENT_SOURCE_DIR}/test_icu4c_integration.cpp"
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
    "${CMAKE_CURRENT_SOURCE_DIR}/test_bzip2_integration.cpp"
    LABELS
        bzip2
        compression
        thirdparty
        integration
    TIMEOUT 30
)

# libsodium integration test
add_module_test(thirdparty_libsodium
    "${CMAKE_CURRENT_SOURCE_DIR}/test_libsodium_integration.cpp"
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
    "${CMAKE_CURRENT_SOURCE_DIR}/test_libstemmer_integration.cpp"
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
    "${CMAKE_CURRENT_SOURCE_DIR}/test_protobuf_integration.cpp"
    LABELS
        protobuf
        serialization
        rpc
        data-formats
        thirdparty
        integration
    TIMEOUT 30
)

# thrift integration test
add_module_test(thirdparty_thrift
    "${CMAKE_CURRENT_SOURCE_DIR}/test_thrift_integration.cpp"
    LABELS
        thrift
        serialization
        rpc
        data-formats
        thirdparty
        integration
    TIMEOUT 30
)
