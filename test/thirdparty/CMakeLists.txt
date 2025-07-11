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
