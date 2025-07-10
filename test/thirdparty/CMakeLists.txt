# Third-party libraries integration tests

# Abseil integration test
add_module_test(thirdparty_abseil
    "${CMAKE_CURRENT_SOURCE_DIR}/test_abseil_integration.cpp"
    LIBRARIES
        absl::strings
        absl::flat_hash_map
        absl::hash
        absl::time
        absl::civil_time
        absl::status
        absl::statusor
    LABELS
        abseil
        thirdparty
        integration
    TIMEOUT 30
)

# GTest/GMock integration test
add_module_test(thirdparty_gtest
    "${CMAKE_CURRENT_SOURCE_DIR}/test_gtest_integration.cpp"
    LIBRARIES
        GTest::gmock
        GTest::gmock_main
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
    LIBRARIES
        GTest::gmock
        absl::strings
        absl::flat_hash_map
        absl::time
        absl::status
        absl::statusor
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
    LIBRARIES
        gflags_static
    LABELS
        gflags
        thirdparty
        integration
    TIMEOUT 30
)
