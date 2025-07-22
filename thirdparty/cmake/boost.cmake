# Boost third-party integration
# Reference: https://github.com/boostorg/boost
# Dependencies: None

# This configuration provides Boost static libraries using the official b2 build system
# and utilizes the official CMake configuration files provided by Boost.

# Force Boost to be linked statically throughout this project.
# This is set as a CACHE variable to ensure it's visible in all scopes,
# especially for the find_package call at the end of this file.
set(Boost_USE_STATIC_LIBS ON CACHE BOOL "Force static linking for Boost")
set(Boost_USE_STATIC_RUNTIME ON CACHE BOOL "Force static runtime for Boost")

thirdparty_check_dependencies("boost")

# Set up directories
set(BOOST_NAME "boost")
set(BOOST_DOWNLOAD_FILE "${THIRDPARTY_DOWNLOAD_DIR}/boost-${BOOST_VERSION}.tar.gz")
set(BOOST_SOURCE_DIR "${THIRDPARTY_SRC_DIR}/${BOOST_NAME}")
set(BOOST_BUILD_DIR "${THIRDPARTY_BUILD_DIR}/${BOOST_NAME}")
set(BOOST_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/${BOOST_NAME}")

get_filename_component(BOOST_INSTALL_DIR "${BOOST_INSTALL_DIR}" ABSOLUTE)

# Download and extract Boost
thirdparty_download_and_check("${BOOST_URL}" "${BOOST_DOWNLOAD_FILE}" "${BOOST_SHA256}")
if(NOT EXISTS "${BOOST_SOURCE_DIR}/bootstrap.sh")
    thirdparty_extract_and_rename("${BOOST_DOWNLOAD_FILE}" "${BOOST_SOURCE_DIR}" "${THIRDPARTY_SRC_DIR}/boost_*")
endif()

# Custom Boost configuration and build function
function(boost_configure_and_build)
    if(NOT CMAKE_BUILD_PARALLEL_LEVEL)
        set(CMAKE_BUILD_PARALLEL_LEVEL 4)
    endif()

    if(CMAKE_SYSTEM_PROCESSOR MATCHES "arm64|aarch64")
        set(BOOST_ARCHITECTURE "arm")
        set(BOOST_ADDRESS_MODEL "64")
    else()
        set(BOOST_ARCHITECTURE "x86")
        set(BOOST_ADDRESS_MODEL "64")
    endif()

    # Configure build options for b2.
    # We build ONLY the required static release libraries to avoid ambiguity.
    set(BOOST_B2_OPTIONS
        variant=release
        link=static
        runtime-link=static
        threading=multi
        cxxstd=17
        address-model=${BOOST_ADDRESS_MODEL}
        architecture=${BOOST_ARCHITECTURE}
        --layout=tagged
        --prefix=${BOOST_INSTALL_DIR}
        --build-dir=${BOOST_BUILD_DIR}
        # Folly's required components
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
        --with-iostreams
        --with-json
        --with-log
        --with-math
        --with-program_options
        --with-random
        --with-regex
        --with-serialization
        --with-stacktrace
        --with-system
        --with-thread
        --with-timer
        --with-url
        --with-wave
        headers
        -j${CMAKE_BUILD_PARALLEL_LEVEL}
    )

    if(NOT EXISTS "${BOOST_SOURCE_DIR}/b2")
        message(STATUS "Bootstrapping Boost b2...")
        execute_process(
            COMMAND bash bootstrap.sh --prefix=${BOOST_INSTALL_DIR}
            WORKING_DIRECTORY "${BOOST_SOURCE_DIR}"
            RESULT_VARIABLE _bootstrap_result
        )
        if(NOT _bootstrap_result EQUAL 0)
            message(FATAL_ERROR "Failed to bootstrap Boost b2.")
        endif()
    endif()

    message(STATUS "Building and installing Boost libraries...")
    message(STATUS "Build options: ${BOOST_B2_OPTIONS}")
    file(MAKE_DIRECTORY "${BOOST_BUILD_DIR}")

    # Build and install in one step
    execute_process(
        COMMAND ./b2 install ${BOOST_B2_OPTIONS}
        WORKING_DIRECTORY "${BOOST_SOURCE_DIR}"
        RESULT_VARIABLE _build_result
    )
    if(NOT _build_result EQUAL 0)
        message(FATAL_ERROR "Failed to build and install Boost.")
    endif()
    message(STATUS "Boost built and installed successfully")
endfunction()

# Check if Boost is already built and installed
set(BOOST_VALIDATION_FILES
    "${BOOST_INSTALL_DIR}/lib/cmake/Boost-${BOOST_VERSION}/BoostConfig.cmake"
    "${BOOST_INSTALL_DIR}/lib/libboost_context-mt-s-a64.a"
    "${BOOST_INSTALL_DIR}/lib/libboost_system-mt-s-a64.a"
)

set(_all_files_exist TRUE)
foreach(_file IN LISTS BOOST_VALIDATION_FILES)
    if(NOT EXISTS "${_file}")
        set(_all_files_exist FALSE)
        break()
    endif()
endforeach()

if(NOT _all_files_exist)
    message(STATUS "Boost not found or incomplete, building...")
    boost_configure_and_build()
else()
    message(STATUS "Boost already built and configured")
endif()

# Export Boost following project standards
if(EXISTS "${BOOST_INSTALL_DIR}/lib/cmake/Boost-${BOOST_VERSION}/BoostConfig.cmake")
    list(APPEND CMAKE_PREFIX_PATH "${BOOST_INSTALL_DIR}")
    set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" PARENT_SCOPE)
    set(Boost_DIR "${BOOST_INSTALL_DIR}/lib/cmake/Boost-${BOOST_VERSION}" CACHE PATH "Boost cmake config directory" FORCE)
    set(Boost_USE_STATIC_LIBS ON PARENT_SCOPE)
    
    # Import Boost package immediately with all required components
    find_package(Boost REQUIRED CONFIG COMPONENTS 
        system filesystem thread chrono date_time regex program_options 
        iostreams random context coroutine atomic container log timer
        serialization math json stacktrace_basic url wave
        fiber exception graph QUIET)
        
    message(STATUS "Boost found and exported globally: ${BOOST_INSTALL_DIR}")
else()
    message(FATAL_ERROR "Boost configuration failed - missing config files")
endif()
