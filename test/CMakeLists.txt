# Test Configuration for Halo Project

# Enable testing functionality
enable_testing()

# Set test output directory
set(TEST_OUTPUT_DIR "${CMAKE_BINARY_DIR}/test")
file(MAKE_DIRECTORY "${TEST_OUTPUT_DIR}")

# Generic test function: creates test executable files
function(add_module_test module_name test_sources)
    set(options PERFORMANCE)
    set(oneValueArgs TIMEOUT WORKING_DIRECTORY)
    set(multiValueArgs LIBRARIES LABELS DEPENDENCIES LINK_LIBRARIES HEADER_INCLUDES CUSTOM_TARGETS)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    
    # Create test executable
    set(test_target "test_${module_name}")
    add_executable(${test_target} ${test_sources})
    
    # Set output directory
    set_target_properties(${test_target}
        PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${TEST_OUTPUT_DIR}"
        OUTPUT_NAME "${test_target}"
    )
    
    # Link libraries
    target_link_libraries(${test_target}
        PRIVATE
        halo_thirdparty_core
        halo_thirdparty_test
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
    
    # Set working directory
    if(ARG_WORKING_DIRECTORY)
        set_tests_properties(${test_name} PROPERTIES
            WORKING_DIRECTORY "${ARG_WORKING_DIRECTORY}")
    endif()
    
    # Add dependencies
    if(ARG_DEPENDENCIES)
        add_dependencies(${test_target} ${ARG_DEPENDENCIES})
    endif()
    
    message(STATUS "Added test module: ${test_name}")
endfunction()

# Add test subdirectories
add_subdirectory(thirdparty)
