# Status test
add_module_test(common_base_status
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_status.cpp"
    LABELS
      status
    TIMEOUT 30
)

# StatusOr test
add_module_test(common_base_status_or
    TEST_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test_status_or.cpp"
    LABELS
      status
      status_or
    TIMEOUT 30
)
