# Boost third-party integration
# Reference: https://github.com/boostorg/boost
# Dependencies: None
#
# This configuration provides Boost static libraries using the official b2 build system
# and utilizes the official CMake configuration files provided by Boost

# Check dependencies using the new dependency management system
thirdparty_check_dependencies("boost")

# Set up directories (variables from ComponentsInfo.cmake)
set(BOOST_NAME "boost")
set(BOOST_DOWNLOAD_FILE "${THIRDPARTY_DOWNLOAD_DIR}/boost_${BOOST_VERSION_UNDERSCORE}.tar.gz")
set(BOOST_SOURCE_DIR "${THIRDPARTY_SRC_DIR}/${BOOST_NAME}")
set(BOOST_BUILD_DIR "${THIRDPARTY_BUILD_DIR}/${BOOST_NAME}")
set(BOOST_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/${BOOST_NAME}")

# Make sure the installation directory is absolute
get_filename_component(BOOST_INSTALL_DIR "${BOOST_INSTALL_DIR}" ABSOLUTE)

# Download and extract Boost
thirdparty_download_and_check("${BOOST_URL}" "${BOOST_DOWNLOAD_FILE}" "${BOOST_SHA256}")

if(NOT EXISTS "${BOOST_SOURCE_DIR}/bootstrap.sh")
    thirdparty_extract_and_rename("${BOOST_DOWNLOAD_FILE}" "${BOOST_SOURCE_DIR}" "${THIRDPARTY_SRC_DIR}/boost_*")
endif()

# Custom Boost configuration and build function
# Boost uses its own b2 build system, similar to how OpenSSL uses Configure
function(boost_configure_and_build)
    # Set parallel build level
    if(NOT CMAKE_BUILD_PARALLEL_LEVEL)
        set(CMAKE_BUILD_PARALLEL_LEVEL 4)
    endif()

    # Detect target architecture
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "arm64|aarch64")
        set(BOOST_ARCHITECTURE "arm")
        set(BOOST_ADDRESS_MODEL "64")
    elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64")
        set(BOOST_ARCHITECTURE "x86")
        set(BOOST_ADDRESS_MODEL "64")
    else()
        set(BOOST_ARCHITECTURE "x86")
        set(BOOST_ADDRESS_MODEL "64")
    endif()
    
    # Configure build options for b2 according to official documentation
    # Include all compiled libraries from https://www.boost.org/doc/user-guide/header-organization-compilation.html
    set(BOOST_B2_OPTIONS
        variant=release
        link=static
        runtime-link=static
        threading=multi
        cxxstd=17
        address-model=${BOOST_ADDRESS_MODEL}
        architecture=${BOOST_ARCHITECTURE}
        --layout=system
        --prefix=${BOOST_INSTALL_DIR}
        --build-dir=${BOOST_BUILD_DIR}
        # All compiled libraries according to official documentation
        --with-atomic
        --with-chrono
        --with-container
        --with-context
        --with-coroutine
        --with-date_time
        --with-exception
        --with-fiber
        --with-filesystem
        --with-graph
        --with-graph_parallel
        --with-iostreams
        --with-json
        --with-locale
        --with-log
        --with-math
        --with-mpi
        --with-nowide
        --with-program_options
        --with-python
        --with-random
        --with-regex
        --with-serialization
        --with-stacktrace
        --with-system
        --with-test
        --with-thread
        --with-timer
        --with-type_erasure
        --with-url
        --with-wave
        headers
        -j${CMAKE_BUILD_PARALLEL_LEVEL}
    )

    # Bootstrap b2 if needed
    if(NOT EXISTS "${BOOST_SOURCE_DIR}/b2")
        message(STATUS "Bootstrapping Boost b2...")
        
        # Run bootstrap script
        execute_process(
            COMMAND bash bootstrap.sh --prefix=${BOOST_INSTALL_DIR}
            WORKING_DIRECTORY "${BOOST_SOURCE_DIR}"
            RESULT_VARIABLE _bootstrap_result
            OUTPUT_VARIABLE _bootstrap_output
            ERROR_VARIABLE _bootstrap_error
        )
        
        if(NOT _bootstrap_result EQUAL 0)
            message(FATAL_ERROR "Failed to bootstrap Boost b2:\nOutput: ${_bootstrap_output}\nError: ${_bootstrap_error}")
        endif()
        
        message(STATUS "Boost b2 bootstrapped successfully")
    endif()

    # Build Boost libraries
    message(STATUS "Building Boost libraries...")
    message(STATUS "Build options: ${BOOST_B2_OPTIONS}")
    
    # Create build directory
    file(MAKE_DIRECTORY "${BOOST_BUILD_DIR}")
    
    # Build with b2
    execute_process(
        COMMAND ./b2 ${BOOST_B2_OPTIONS}
        WORKING_DIRECTORY "${BOOST_SOURCE_DIR}"
        RESULT_VARIABLE _build_result
        OUTPUT_VARIABLE _build_output
        ERROR_VARIABLE _build_error
    )
    
    if(NOT _build_result EQUAL 0)
        message(STATUS "Boost build output: ${_build_output}")
        message(STATUS "Boost build error: ${_build_error}")
        message(FATAL_ERROR "Failed to build Boost with result code: ${_build_result}")
    endif()
    
    # Install with b2 - this automatically generates and installs CMake files
    message(STATUS "Installing Boost with official CMake files...")
    execute_process(
        COMMAND ./b2 install ${BOOST_B2_OPTIONS}
        WORKING_DIRECTORY "${BOOST_SOURCE_DIR}"
        RESULT_VARIABLE _install_result
        OUTPUT_VARIABLE _install_output
        ERROR_VARIABLE _install_error
    )
    
    if(NOT _install_result EQUAL 0)
        message(STATUS "Boost install output: ${_install_output}")
        message(STATUS "Boost install error: ${_install_error}")
        message(FATAL_ERROR "Failed to install Boost with result code: ${_install_result}")
    endif()
    
    message(STATUS "Boost built and installed successfully")
endfunction()

# Check if Boost is already built and installed
message(STATUS "Boost version: ${BOOST_VERSION}")
message(STATUS "Boost install dir: ${BOOST_INSTALL_DIR}")

set(BOOST_VALIDATION_FILES
    "${BOOST_INSTALL_DIR}/lib/libboost_system.a"
    "${BOOST_INSTALL_DIR}/lib/libboost_filesystem.a"
    "${BOOST_INSTALL_DIR}/lib/libboost_thread.a"
    "${BOOST_INSTALL_DIR}/lib/libboost_chrono.a"
    "${BOOST_INSTALL_DIR}/include/boost/version.hpp"
    "${BOOST_INSTALL_DIR}/lib/cmake/Boost-${BOOST_VERSION}/BoostConfig.cmake"
    "${BOOST_INSTALL_DIR}/lib/cmake/Boost-${BOOST_VERSION}/BoostConfigVersion.cmake"
)

# Check if all validation files exist
set(_all_files_exist TRUE)
message(STATUS "Boost validation files to check:")
foreach(_file IN LISTS BOOST_VALIDATION_FILES)
    message(STATUS "  - ${_file}")
    if(NOT EXISTS "${_file}")
        message(STATUS "    MISSING: ${_file}")
        set(_all_files_exist FALSE)
        break()
    else()
        message(STATUS "    EXISTS: ${_file}")
    endif()
endforeach()

message(STATUS "Boost validation result: _all_files_exist=${_all_files_exist}")

if(NOT _all_files_exist)
    message(STATUS "Boost not found or incomplete, building...")
    boost_configure_and_build()
else()
    message(STATUS "Boost already built and configured")
endif()

# Export Boost following project standards
if(EXISTS "${BOOST_INSTALL_DIR}/lib/cmake/Boost-${BOOST_VERSION}/BoostConfig.cmake")
    # Add to CMAKE_PREFIX_PATH for standard discovery
    list(APPEND CMAKE_PREFIX_PATH "${BOOST_INSTALL_DIR}")
    set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" PARENT_SCOPE)
    
    # Set Boost_DIR for explicit config location
    set(Boost_DIR "${BOOST_INSTALL_DIR}/lib/cmake/Boost-${BOOST_VERSION}" CACHE PATH "Boost cmake config directory" FORCE)
    
    # Configure Boost for static linking (set in both current and parent scope)
    set(Boost_USE_STATIC_LIBS ON)
    set(Boost_USE_STATIC_RUNTIME ON)
    set(Boost_USE_MULTITHREADED ON)
    
    # Export to parent scope as well
    set(Boost_USE_STATIC_LIBS ON PARENT_SCOPE)
    set(Boost_USE_STATIC_RUNTIME ON PARENT_SCOPE)
    set(Boost_USE_MULTITHREADED ON PARENT_SCOPE)
    
    # Export success status
    set(BOOST_FOUND TRUE PARENT_SCOPE)
    
    message(STATUS "Boost found and exported globally: ${BOOST_INSTALL_DIR}")
else()
    message(FATAL_ERROR "Boost configuration failed - missing config files")
endif()
