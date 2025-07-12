# jemalloc third-party integration
# Reference: https://github.com/jemalloc/jemalloc
# Dependencies: None

# Check dependencies using the new dependency management system
thirdparty_check_dependencies("jemalloc")

# Set up directories (variables from ComponentsInfo.cmake)
set(JEMALLOC_NAME "jemalloc")
set(JEMALLOC_DOWNLOAD_FILE "${THIRDPARTY_DOWNLOAD_DIR}/jemalloc-${JEMALLOC_VERSION}.tar.bz2")
set(JEMALLOC_SOURCE_DIR "${THIRDPARTY_SRC_DIR}/${JEMALLOC_NAME}")
set(JEMALLOC_BUILD_DIR "${THIRDPARTY_BUILD_DIR}/${JEMALLOC_NAME}")
set(JEMALLOC_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/${JEMALLOC_NAME}")

# Make sure the installation directory is absolute
get_filename_component(JEMALLOC_INSTALL_DIR "${JEMALLOC_INSTALL_DIR}" ABSOLUTE)

# Download and extract jemalloc
thirdparty_download_and_check("${JEMALLOC_URL}" "${JEMALLOC_DOWNLOAD_FILE}" "${JEMALLOC_SHA256}")

if(NOT EXISTS "${JEMALLOC_SOURCE_DIR}/configure")
    thirdparty_extract_and_rename("${JEMALLOC_DOWNLOAD_FILE}" "${JEMALLOC_SOURCE_DIR}" "${THIRDPARTY_SRC_DIR}/jemalloc-*")
endif()

# Configure jemalloc with autotools (jemalloc doesn't use CMake)
# Enable BOTH drop-in replacement AND public API (like Facebook's usage)
set(JEMALLOC_CONFIG_ARGS
    --prefix=${JEMALLOC_INSTALL_DIR}
    --enable-static
    --disable-shared
    --disable-debug
    --enable-prof
    --enable-prof-libunwind
    --enable-stats
    --enable-fill
    --enable-utrace
    --enable-xmalloc
    --enable-munmap
    # NO prefix = drop-in replacement (malloc/free work)
    # BUT we also get je_* functions automatically
    # This is the Facebook/Meta approach
    --enable-opt-safety-checks
)

# Configure jemalloc
if(NOT EXISTS "${JEMALLOC_BUILD_DIR}/Makefile")
    message(STATUS "Configuring jemalloc...")
    
    # Create build directory
    file(MAKE_DIRECTORY "${JEMALLOC_BUILD_DIR}")
    
    # Run autogen.sh if needed
    if(EXISTS "${JEMALLOC_SOURCE_DIR}/autogen.sh")
        execute_process(
            COMMAND bash autogen.sh
            WORKING_DIRECTORY "${JEMALLOC_SOURCE_DIR}"
            RESULT_VARIABLE _autogen_result
        )
        if(NOT _autogen_result EQUAL 0)
            message(FATAL_ERROR "Failed to run autogen.sh for jemalloc")
        endif()
    endif()
    
    # Configure with autotools
    execute_process(
        COMMAND ${JEMALLOC_SOURCE_DIR}/configure ${JEMALLOC_CONFIG_ARGS}
        WORKING_DIRECTORY "${JEMALLOC_BUILD_DIR}"
        RESULT_VARIABLE _configure_result
    )
    
    if(NOT _configure_result EQUAL 0)
        message(FATAL_ERROR "Failed to configure jemalloc")
    endif()
    
    message(STATUS "jemalloc configured successfully")
endif()

# Build jemalloc
if(NOT EXISTS "${JEMALLOC_INSTALL_DIR}/lib/libjemalloc.a")
    message(STATUS "Building jemalloc...")
    
    # Build
    execute_process(
        COMMAND make -j${CMAKE_BUILD_PARALLEL_LEVEL}
        WORKING_DIRECTORY "${JEMALLOC_BUILD_DIR}"
        RESULT_VARIABLE _build_result
    )
    
    if(NOT _build_result EQUAL 0)
        message(FATAL_ERROR "Failed to build jemalloc")
    endif()
    
    # Install
    execute_process(
        COMMAND make install
        WORKING_DIRECTORY "${JEMALLOC_BUILD_DIR}"
        RESULT_VARIABLE _install_result
    )
    
    if(NOT _install_result EQUAL 0)
        message(FATAL_ERROR "Failed to install jemalloc")
    endif()
    
    message(STATUS "jemalloc built and installed successfully")
endif()

# Validate installation
if(NOT EXISTS "${JEMALLOC_INSTALL_DIR}/lib/libjemalloc.a")
    message(FATAL_ERROR "jemalloc installation validation failed: static library not found")
endif()

if(NOT EXISTS "${JEMALLOC_INSTALL_DIR}/include/jemalloc/jemalloc.h")
    message(FATAL_ERROR "jemalloc installation validation failed: header not found")
endif()

# Create imported target for jemalloc
add_library(jemalloc::jemalloc STATIC IMPORTED GLOBAL)
set_target_properties(jemalloc::jemalloc PROPERTIES
    IMPORTED_LOCATION "${JEMALLOC_INSTALL_DIR}/lib/libjemalloc.a"
    INTERFACE_INCLUDE_DIRECTORIES "${JEMALLOC_INSTALL_DIR}/include"
    # Enable drop-in replacement: force load jemalloc to override system malloc
    INTERFACE_LINK_OPTIONS "$<$<PLATFORM_ID:Darwin>:-Wl,-force_load,${JEMALLOC_INSTALL_DIR}/lib/libjemalloc.a>$<$<PLATFORM_ID:Linux>:-Wl,--whole-archive,${JEMALLOC_INSTALL_DIR}/lib/libjemalloc.a,-Wl,--no-whole-archive>"
    # Add compile definitions to indicate jemalloc is available
    INTERFACE_COMPILE_DEFINITIONS "USE_JEMALLOC=1;FOLLY_USE_JEMALLOC=1"
)

# Export jemalloc to global scope
list(APPEND CMAKE_PREFIX_PATH "${JEMALLOC_INSTALL_DIR}")
set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" PARENT_SCOPE)
set(jemalloc_DIR "${JEMALLOC_INSTALL_DIR}" CACHE PATH "Path to installed jemalloc" FORCE)

message(STATUS "jemalloc integration completed successfully")