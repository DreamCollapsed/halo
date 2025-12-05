# Test Configuration for Halo Project

# Enable testing functionality
enable_testing()

# Set test output directory
set(TEST_OUTPUT_DIR "${CMAKE_BINARY_DIR}/test")
file(MAKE_DIRECTORY "${TEST_OUTPUT_DIR}")

# Generic test function implementation
function(_add_halo_test_impl module_name)
    set(options PERFORMANCE SERIAL)
    set(oneValueArgs TIMEOUT WORKING_DIRECTORY)
    set(multiValueArgs TEST_SOURCES LIBRARIES LABELS DEPENDENCIES LINK_LIBRARIES HEADER_INCLUDES CUSTOM_TARGETS DEFAULT_LIBRARIES)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    
    # Create test executable
    set(test_target "test_${module_name}")
    add_executable(${test_target} ${ARG_TEST_SOURCES})
    
    # Set output directory
    set_target_properties(${test_target}
        PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${TEST_OUTPUT_DIR}"
        OUTPUT_NAME "${test_target}"
    )
    
    # Link libraries
    target_link_libraries(${test_target}
        PRIVATE
        ${ARG_DEFAULT_LIBRARIES}
        ${ARG_CUSTOM_TARGETS}
        ${ARG_LIBRARIES}
        ${ARG_LINK_LIBRARIES}
    )
    # Apply additional include directories if provided (e.g., Folly headers)
    if(ARG_HEADER_INCLUDES)
        target_include_directories(${test_target} PRIVATE ${ARG_HEADER_INCLUDES})
    endif()
    
    # Add to CTest
    set(test_name "${module_name}_ut")
    add_test(NAME ${test_name} COMMAND ${test_target})
    
    # Set test properties
    set(test_labels "unit;${module_name}")
    if(ARG_LABELS)
        list(APPEND test_labels ${ARG_LABELS})
    endif()
    if(ARG_PERFORMANCE)
        list(APPEND test_labels "performance")
    endif()
    
    # Set timeout with default value if not specified
    if(NOT ARG_TIMEOUT)
        set(ARG_TIMEOUT 300)  # 5 minutes default
    endif()
    
    set_tests_properties(${test_name} PROPERTIES
        LABELS "${test_labels}"
        TIMEOUT ${ARG_TIMEOUT}
    )

    if(ARG_SERIAL)
        set_tests_properties(${test_name} PROPERTIES RUN_SERIAL TRUE)
    endif()
    
    # Set working directory
    if(ARG_WORKING_DIRECTORY)
        set_tests_properties(${test_name} PROPERTIES
            WORKING_DIRECTORY "${ARG_WORKING_DIRECTORY}")
    endif()
    
    # Add dependencies
    if(ARG_DEPENDENCIES)
        add_dependencies(${test_target} ${ARG_DEPENDENCIES})
    endif()
    
    message(DEBUG "Added test module: ${test_name}")
endfunction()

# Standard module test: links common_base, thirdparty_core, thirdparty_test
function(add_module_test module_name)
    _add_halo_test_impl(${module_name}
        DEFAULT_LIBRARIES halo_common_base halo_thirdparty_core halo_thirdparty_test
        ${ARGN}
    )
endfunction()

# Base module test: links common_base, thirdparty_test ONLY
# Use this for low-level components that don't depend on heavy thirdparty libs
function(add_base_test module_name)
    _add_halo_test_impl(${module_name}
        DEFAULT_LIBRARIES halo_common_base halo_thirdparty_test
        ${ARGN}
    )
endfunction()

# Add test subdirectories
add_subdirectory(thirdparty)
add_subdirectory(common)
