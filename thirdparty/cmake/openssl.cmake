# OpenSSL third-party integration
# Reference: https://github.com/openssl/openssl
# OpenSSL uses its own Configure script, not CMake, but provides professional CMake config files

# Check dependencies (OpenSSL has no dependencies)
thirdparty_check_dependencies("openssl")

# Set up directories (variables from ComponentsInfo.cmake)
set(OPENSSL_NAME "openssl")
set(OPENSSL_DOWNLOAD_FILE "${THIRDPARTY_DOWNLOAD_DIR}/openssl-${OPENSSL_VERSION}.tar.gz")
set(OPENSSL_SOURCE_DIR "${THIRDPARTY_SRC_DIR}/${OPENSSL_NAME}")
set(OPENSSL_BUILD_DIR "${THIRDPARTY_BUILD_DIR}/${OPENSSL_NAME}")
set(OPENSSL_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/${OPENSSL_NAME}")

# Make sure the installation directory is absolute
get_filename_component(OPENSSL_INSTALL_DIR "${OPENSSL_INSTALL_DIR}" ABSOLUTE)

# Download and extract OpenSSL
thirdparty_download_and_check("${OPENSSL_URL}" "${OPENSSL_DOWNLOAD_FILE}" "${OPENSSL_SHA256}")
thirdparty_extract_and_rename("${OPENSSL_DOWNLOAD_FILE}" "${OPENSSL_SOURCE_DIR}" "${THIRDPARTY_SRC_DIR}/openssl-*")

# Custom OpenSSL configuration and build function
# OpenSSL doesn't use CMake - it uses its own Configure script and make system
function(openssl_configure_and_build)
    # Determine platform-specific configuration
    if(APPLE)
        if(CMAKE_SYSTEM_PROCESSOR MATCHES "arm64|aarch64")
            set(OPENSSL_PLATFORM "darwin64-arm64-cc")
        else()
            set(OPENSSL_PLATFORM "darwin64-x86_64-cc")
        endif()
    elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
        if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64")
            set(OPENSSL_PLATFORM "linux-x86_64")
        elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
            set(OPENSSL_PLATFORM "linux-aarch64")
        else()
            set(OPENSSL_PLATFORM "linux-generic64")
        endif()
    else()
        message(FATAL_ERROR "Unsupported platform for OpenSSL: ${CMAKE_SYSTEM_NAME}")
    endif()

    # Optimized OpenSSL configuration options
    set(OPENSSL_CONFIG_OPTIONS
        --prefix=${OPENSSL_INSTALL_DIR}
        --openssldir=${OPENSSL_INSTALL_DIR}/ssl
        --libdir=lib
        no-shared no-tests no-apps no-docs no-engine no-deprecated
        # Essential algorithms
        enable-chacha enable-poly1305 enable-blake2 enable-aria
        enable-sm2 enable-sm3 enable-sm4 enable-tls1_3
        enable-ssl3 enable-ssl3-method enable-ocsp enable-cms
        enable-ts enable-scrypt enable-argon2 enable-zlib
        enable-async enable-pic enable-fips
        # Platform-specific exclusions
        no-sctp no-asan no-msan no-ubsan
    )

    # Add build type optimization
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        list(APPEND OPENSSL_CONFIG_OPTIONS --debug)
    else()
        list(APPEND OPENSSL_CONFIG_OPTIONS --release)
    endif()

    # Configure OpenSSL with environment variables
    message(STATUS "Configuring OpenSSL with platform: ${OPENSSL_PLATFORM}")
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E env
            CC=${CMAKE_C_COMPILER}
            CXX=${CMAKE_CXX_COMPILER}
            ./Configure ${OPENSSL_PLATFORM} ${OPENSSL_CONFIG_OPTIONS}
        WORKING_DIRECTORY ${OPENSSL_SOURCE_DIR}
        RESULT_VARIABLE OPENSSL_CONFIGURE_RESULT
        OUTPUT_VARIABLE OPENSSL_CONFIGURE_OUTPUT
        ERROR_VARIABLE OPENSSL_CONFIGURE_ERROR
    )

    if(NOT OPENSSL_CONFIGURE_RESULT EQUAL 0)
        message(FATAL_ERROR "OpenSSL configuration failed: ${OPENSSL_CONFIGURE_ERROR}")
    endif()

    # Build OpenSSL libraries only (no apps)
    message(STATUS "Building OpenSSL libraries...")
    execute_process(
        COMMAND make -j${CMAKE_BUILD_PARALLEL_LEVEL} build_libs
        WORKING_DIRECTORY ${OPENSSL_SOURCE_DIR}
        RESULT_VARIABLE OPENSSL_BUILD_RESULT
        OUTPUT_VARIABLE OPENSSL_BUILD_OUTPUT
        ERROR_VARIABLE OPENSSL_BUILD_ERROR
    )

    if(NOT OPENSSL_BUILD_RESULT EQUAL 0)
        message(FATAL_ERROR "OpenSSL build failed: ${OPENSSL_BUILD_ERROR}")
    endif()

    # Install OpenSSL - this automatically generates and installs CMake files
    message(STATUS "Installing OpenSSL with official CMake files...")
    execute_process(
        COMMAND make install_sw install_ssldirs
        WORKING_DIRECTORY ${OPENSSL_SOURCE_DIR}
        RESULT_VARIABLE OPENSSL_INSTALL_RESULT
        OUTPUT_VARIABLE OPENSSL_INSTALL_OUTPUT
        ERROR_VARIABLE OPENSSL_INSTALL_ERROR
    )

    if(NOT OPENSSL_INSTALL_RESULT EQUAL 0)
        message(FATAL_ERROR "OpenSSL installation failed: ${OPENSSL_INSTALL_ERROR}")
    endif()
endfunction()

# Check if OpenSSL is already built and installed
set(OPENSSL_VALIDATION_FILES
    "${OPENSSL_INSTALL_DIR}/lib/libssl.a"
    "${OPENSSL_INSTALL_DIR}/lib/libcrypto.a"
    "${OPENSSL_INSTALL_DIR}/include/openssl/ssl.h"
    "${OPENSSL_INSTALL_DIR}/include/openssl/crypto.h"
    "${OPENSSL_INSTALL_DIR}/lib/cmake/OpenSSL/OpenSSLConfig.cmake"
    "${OPENSSL_INSTALL_DIR}/lib/cmake/OpenSSL/OpenSSLConfigVersion.cmake"
)

# Check if all validation files exist
set(_all_files_exist TRUE)
foreach(_file IN LISTS OPENSSL_VALIDATION_FILES)
    if(NOT EXISTS "${_file}")
        set(_all_files_exist FALSE)
        break()
    endif()
endforeach()

if(NOT _all_files_exist)
    message(STATUS "OpenSSL not found or incomplete, building...")
    openssl_configure_and_build()
else()
    message(STATUS "OpenSSL already built and configured")
endif()

# Export OpenSSL following project standards
if(EXISTS "${OPENSSL_INSTALL_DIR}/lib/cmake/OpenSSL/OpenSSLConfig.cmake")
    # Add to CMAKE_PREFIX_PATH for standard discovery
    list(APPEND CMAKE_PREFIX_PATH "${OPENSSL_INSTALL_DIR}")
    set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" PARENT_SCOPE)
    
    # Set OpenSSL_DIR for explicit config location
    set(OpenSSL_DIR "${OPENSSL_INSTALL_DIR}/lib/cmake/OpenSSL" CACHE PATH "OpenSSL cmake config directory" FORCE)
    
    # Export success status
    set(OPENSSL_FOUND TRUE PARENT_SCOPE)
    
    message(STATUS "OpenSSL found and exported globally: ${OPENSSL_INSTALL_DIR}")
    
    # OpenSSL::SSL and OpenSSL::Crypto targets are created by official config
    # macOS linker warning suppression is handled in the main CMakeLists.txt
else()
    message(FATAL_ERROR "OpenSSL configuration failed - missing config files")
endif()
