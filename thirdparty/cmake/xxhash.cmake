# xxHash third-party integration
# Reference: https://github.com/Cyan4973/xxHash

# Set up directories
set(XXHASH_SRC_DIR "${THIRDPARTY_SRC_DIR}/xxhash")
set(XXHASH_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/xxhash")

# Download and extract sources
thirdparty_download_and_check("${XXHASH_URL}" "${THIRDPARTY_DOWNLOAD_DIR}/xxhash-${XXHASH_VERSION}.tar.gz" "${XXHASH_SHA256}")
thirdparty_extract_and_rename("${THIRDPARTY_DOWNLOAD_DIR}/xxhash-${XXHASH_VERSION}.tar.gz" "${XXHASH_SRC_DIR}" "${THIRDPARTY_SRC_DIR}/xxHash-*")

# Build and install xxhash during CMake configure time using execute_process
# This ensures xxhash is built before the main project, not during ninja build
if(NOT EXISTS "${XXHASH_INSTALL_DIR}/lib/libxxhash.a")
    message(STATUS "Building xxhash during configure time...")
    execute_process(
        COMMAND make install_libxxhash.a install_libxxhash.includes "PREFIX=${XXHASH_INSTALL_DIR}" CFLAGS=-fPIC
        WORKING_DIRECTORY "${XXHASH_SRC_DIR}"
        RESULT_VARIABLE _xxhash_build_result
    )
    if(_xxhash_build_result)
        message(FATAL_ERROR "Failed to build xxhash")
    endif()
    message(STATUS "xxhash built and installed successfully")
endif()

# Create an imported target for xxhash so other CMake targets can link against it.
add_library(xxhash_thirdparty_static STATIC IMPORTED GLOBAL)
set_target_properties(xxhash_thirdparty_static PROPERTIES
    IMPORTED_LOCATION "${XXHASH_INSTALL_DIR}/lib/libxxhash.a"
    INTERFACE_INCLUDE_DIRECTORIES "${XXHASH_INSTALL_DIR}/include"
)

# Create a modern CMake alias for easier consumption.
add_library(xxhash::xxhash ALIAS xxhash_thirdparty_static)

message(STATUS "xxhash build configured and completed during configure time.")
