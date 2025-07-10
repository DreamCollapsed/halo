# Main program build configuration
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")

# Create main executable
add_executable(halo main.cpp)

# Link centralized third-party target (replaces individual find_package calls)
target_link_libraries(halo
    PRIVATE
    halo::thirdparty
)

# Platform-specific libraries
if(NOT APPLE)
    target_link_libraries(halo PRIVATE unwind)
endif()
