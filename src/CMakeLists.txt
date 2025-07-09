# Main program build configuration
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")

# Find packages (thirdparty has already set up CMAKE_PREFIX_PATH and cache variables)
find_package(absl REQUIRED CONFIG)

# Create main executable
add_executable(halo main.cpp)

# Link required libraries
target_link_libraries(halo
    PRIVATE
    absl::strings
    absl::str_format
)

# Platform-specific libraries
if(NOT APPLE)
    target_link_libraries(halo PRIVATE unwind)
endif()
