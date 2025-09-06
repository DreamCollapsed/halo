# Main program build configuration
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")

# Create main executable
add_executable(halo main.cpp)

# Link with third-party libraries and Velox
target_link_libraries(halo
    PRIVATE
    halo_thirdparty_core
    halo_thirdparty_with_thrift
    halo_velox_unified
)

# Platform-specific libraries
if(NOT APPLE)
    target_link_libraries(halo PRIVATE unwind)
endif()
