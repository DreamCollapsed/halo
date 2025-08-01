# xxHash third-party integration
# Reference: https://github.com/Cyan4973/xxHash

# Set up directories
set(XXHASH_SRC_DIR "${THIRDPARTY_SRC_DIR}/xxhash")
set(XXHASH_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/xxhash")

# Download and extract sources
thirdparty_download_and_check("${XXHASH_URL}" "${THIRDPARTY_DOWNLOAD_DIR}/xxhash-${XXHASH_VERSION}.tar.gz" "${XXHASH_SHA256}")
thirdparty_extract_and_rename("${THIRDPARTY_DOWNLOAD_DIR}/xxhash-${XXHASH_VERSION}.tar.gz" "${XXHASH_SRC_DIR}" "${THIRDPARTY_SRC_DIR}/xxHash-*")

# Build and install using Makefile.
# We use add_custom_command and add_custom_target to integrate the Makefile build into CMake's dependency graph.
add_custom_command(
    OUTPUT 
        "${XXHASH_INSTALL_DIR}/lib/libxxhash.a"
        "${XXHASH_INSTALL_DIR}/include/xxhash.h"
    COMMAND make -C "${XXHASH_SRC_DIR}" install_libxxhash.a install_libxxhash.includes "PREFIX=${XXHASH_INSTALL_DIR}" CFLAGS=-fPIC
    COMMENT "Building and installing xxhash static library and headers via Makefile"
    VERBATIM
)

add_custom_target(xxhash_build ALL DEPENDS 
    "${XXHASH_INSTALL_DIR}/lib/libxxhash.a"
)

# Create an imported target for xxhash so other CMake targets can link against it.
add_library(xxhash_thirdparty_static STATIC IMPORTED GLOBAL)
set_target_properties(xxhash_thirdparty_static PROPERTIES
    IMPORTED_LOCATION "${XXHASH_INSTALL_DIR}/lib/libxxhash.a"
    INTERFACE_INCLUDE_DIRECTORIES "${XXHASH_INSTALL_DIR}/include"
)

# Ensure the custom build target runs before anything tries to use the imported target.
add_dependencies(xxhash_thirdparty_static xxhash_build)

# Create a modern CMake alias for easier consumption.
add_library(xxhash::xxhash ALIAS xxhash_thirdparty_static)

message(STATUS "xxhash build configured using Makefile.")
