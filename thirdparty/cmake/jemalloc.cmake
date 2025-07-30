# jemalloc third-party integration
# Reference: https://github.com/jemalloc/jemalloc
# Dependencies: None
#
# This configuration provides two jemalloc targets:
# 1. jemalloc::jemalloc     - Standard static library (libjemalloc.a)
# 2. jemalloc::jemalloc_pic - Position Independent Code static library (libjemalloc_pic.a)
# 3. jemalloc::jemalloc_default - Alias to PIC version (recommended)
#
# Use jemalloc::jemalloc_pic when:
# - Building with CMAKE_POSITION_INDEPENDENT_CODE=ON (current project setting)
# - Linking static libraries that might be used in shared libraries
# - Following modern CMake best practices
#
# Use jemalloc::jemalloc when:
# - Specifically need the non-PIC version for performance reasons
# - Linking only to executables (not shared libraries)

# Check dependencies using the new dependency management system
thirdparty_check_dependencies("jemalloc")

# Set up directories using common function
thirdparty_setup_directories("jemalloc")

# Override for jemalloc's .tar.bz2 extension
set(JEMALLOC_DOWNLOAD_FILE "${THIRDPARTY_DOWNLOAD_DIR}/jemalloc-${JEMALLOC_VERSION}.tar.bz2")
get_filename_component(JEMALLOC_INSTALL_DIR "${JEMALLOC_INSTALL_DIR}" ABSOLUTE)

# Build and install jemalloc using the generic autotools function
thirdparty_build_autotools_library(jemalloc
    CONFIGURE_ARGS
        --disable-shared
        --enable-static
        --with-private-namespace=je_halo_
    VALIDATION_FILES
        "${JEMALLOC_INSTALL_DIR}/lib/libjemalloc.a"
        "${JEMALLOC_INSTALL_DIR}/lib/libjemalloc_pic.a"
        "${JEMALLOC_INSTALL_DIR}/include/jemalloc/jemalloc.h"
)

# Validate installation
if(NOT EXISTS "${JEMALLOC_INSTALL_DIR}/lib/libjemalloc.a")
    message(FATAL_ERROR "jemalloc installation validation failed: static library not found")
endif()

if(NOT EXISTS "${JEMALLOC_INSTALL_DIR}/lib/libjemalloc_pic.a")
    message(FATAL_ERROR "jemalloc installation validation failed: PIC static library not found")
endif()

if(NOT EXISTS "${JEMALLOC_INSTALL_DIR}/include/jemalloc/jemalloc.h")
    message(FATAL_ERROR "jemalloc installation validation failed: header not found")
endif()

# Create imported target for jemalloc (standard version)
add_library(jemalloc::jemalloc STATIC IMPORTED GLOBAL)
set_target_properties(jemalloc::jemalloc PROPERTIES
    IMPORTED_LOCATION "${JEMALLOC_INSTALL_DIR}/lib/libjemalloc.a"
    INTERFACE_INCLUDE_DIRECTORIES "${JEMALLOC_INSTALL_DIR}/include"
    # Enable drop-in replacement: force load jemalloc to override system malloc
    INTERFACE_LINK_OPTIONS "$<$<PLATFORM_ID:Darwin>:-Wl,-force_load,${JEMALLOC_INSTALL_DIR}/lib/libjemalloc.a>$<$<PLATFORM_ID:Linux>:-Wl,--whole-archive,${JEMALLOC_INSTALL_DIR}/lib/libjemalloc.a,-Wl,--no-whole-archive>"
    # Add compile definitions to indicate jemalloc is available
    INTERFACE_COMPILE_DEFINITIONS "USE_JEMALLOC=1;FOLLY_USE_JEMALLOC=1"
)

# Create imported target for jemalloc (PIC version) - recommended for modern CMake
add_library(jemalloc::jemalloc_pic STATIC IMPORTED GLOBAL)
set_target_properties(jemalloc::jemalloc_pic PROPERTIES
    IMPORTED_LOCATION "${JEMALLOC_INSTALL_DIR}/lib/libjemalloc_pic.a"
    INTERFACE_INCLUDE_DIRECTORIES "${JEMALLOC_INSTALL_DIR}/include"
    # PIC version is better suited for modern CMake with POSITION_INDEPENDENT_CODE=ON
    INTERFACE_POSITION_INDEPENDENT_CODE ON
    # Enable drop-in replacement: force load jemalloc to override system malloc
    INTERFACE_LINK_OPTIONS "$<$<PLATFORM_ID:Darwin>:-Wl,-force_load,${JEMALLOC_INSTALL_DIR}/lib/libjemalloc_pic.a>$<$<PLATFORM_ID:Linux>:-Wl,--whole-archive,${JEMALLOC_INSTALL_DIR}/lib/libjemalloc_pic.a,-Wl,--no-whole-archive>"
    # Add compile definitions to indicate jemalloc is available
    INTERFACE_COMPILE_DEFINITIONS "USE_JEMALLOC=1;FOLLY_USE_JEMALLOC=1"
)

# Create an alias that points to the PIC version by default (recommended)
# This ensures compatibility with CMAKE_POSITION_INDEPENDENT_CODE=ON
add_library(jemalloc::jemalloc_default ALIAS jemalloc::jemalloc_pic)

# Export jemalloc to global scope
list(APPEND CMAKE_PREFIX_PATH "${JEMALLOC_INSTALL_DIR}")
set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" CACHE INTERNAL "Updated CMAKE_PREFIX_PATH with jemalloc" FORCE)
set(jemalloc_DIR "${JEMALLOC_INSTALL_DIR}" CACHE PATH "Path to installed jemalloc" FORCE)

message(STATUS "jemalloc integration completed successfully")