# OpenSSL third-party integration
# Reference: https://github.com/openssl/openssl
# OpenSSL 1.1.1 uses its own Configure script. We manually generate modern
# CMake config files after building it.

thirdparty_check_dependencies("openssl")

# Set up directories using common function
thirdparty_setup_directories("openssl")

# Override specific directory variables
set(OPENSSL_DOWNLOAD_FILE "${THIRDPARTY_DOWNLOAD_DIR}/openssl-${OPENSSL_VERSION}.tar.gz")
set(OPENSSL_SOURCE_DIR "${THIRDPARTY_SRC_DIR}/openssl")
set(OPENSSL_BUILD_DIR "${THIRDPARTY_BUILD_DIR}/openssl") # Note: OpenSSL builds in-source
set(OPENSSL_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/openssl")
get_filename_component(OPENSSL_INSTALL_DIR "${OPENSSL_INSTALL_DIR}" ABSOLUTE)

# Download and extract OpenSSL
thirdparty_download_and_check("${OPENSSL_URL}" "${OPENSSL_DOWNLOAD_FILE}" "${OPENSSL_SHA256}")
thirdparty_extract_and_rename("${OPENSSL_DOWNLOAD_FILE}" "${OPENSSL_SOURCE_DIR}" "${THIRDPARTY_SRC_DIR}/openssl-*")

# Function to manually generate modern CMake config files for OpenSSL
function(openssl_create_cmake_config)
    set(OPENSSL_CMAKE_DIR "${OPENSSL_INSTALL_DIR}/lib/cmake/OpenSSL")
    file(MAKE_DIRECTORY "${OPENSSL_CMAKE_DIR}")

    set(OPENSSL_VERSION_MAJOR "1")
    set(OPENSSL_VERSION_MINOR "1")
    set(OPENSSL_VERSION_PATCH "1")
    set(OPENSSL_VERSION_TWEAK "w")

    # Create OpenSSLConfigVersion.cmake
    set(VERSION_CONFIG_CONTENT "
set(PACKAGE_VERSION \"${OPENSSL_VERSION}\")
if(PACKAGE_VERSION VERSION_LESS PACKAGE_FIND_VERSION)
  set(PACKAGE_VERSION_COMPATIBLE FALSE)
else()
  set(PACKAGE_VERSION_COMPATIBLE TRUE)
  if(PACKAGE_FIND_VERSION_MAJOR STREQUAL \"${OPENSSL_VERSION_MAJOR}\")
    set(PACKAGE_VERSION_EXACT TRUE)
  endif()
endif()
")
    file(WRITE "${OPENSSL_CMAKE_DIR}/OpenSSLConfigVersion.cmake" "${VERSION_CONFIG_CONTENT}")

    # Create OpenSSLTargets.cmake and OpenSSLTargets-release.cmake
    set(TARGETS_CONFIG_CONTENT "
if(NOT TARGET OpenSSL::Crypto)
  add_library(OpenSSL::Crypto STATIC IMPORTED)
endif()
if(NOT TARGET OpenSSL::SSL)
  add_library(OpenSSL::SSL STATIC IMPORTED)
endif()
")
    file(WRITE "${OPENSSL_CMAKE_DIR}/OpenSSLTargets.cmake" "${TARGETS_CONFIG_CONTENT}")

    set(TARGETS_RELEASE_CONFIG_CONTENT "
set_property(TARGET OpenSSL::Crypto APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(OpenSSL::Crypto PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE \"C\"
  IMPORTED_LOCATION_RELEASE \"${OPENSSL_INSTALL_DIR}/lib/libcrypto.a\")
set_property(TARGET OpenSSL::SSL APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(OpenSSL::SSL PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE \"C\"
  IMPORTED_LOCATION_RELEASE \"${OPENSSL_INSTALL_DIR}/lib/libssl.a\"
  INTERFACE_LINK_LIBRARIES \"OpenSSL::Crypto;\$<LINK_ONLY:dl>;\$<LINK_ONLY:pthread>\")
")
    file(WRITE "${OPENSSL_CMAKE_DIR}/OpenSSLTargets-release.cmake" "${TARGETS_RELEASE_CONFIG_CONTENT}")

    # Create OpenSSLConfig.cmake
    set(CONFIG_CONTENT "
include(CMakeFindDependencyMacro)
find_dependency(Threads)

include(\"\${CMAKE_CURRENT_LIST_DIR}/OpenSSLTargets.cmake\")
include(\"\${CMAKE_CURRENT_LIST_DIR}/OpenSSLTargets-release.cmake\")

set(OPENSSL_FOUND TRUE)
set(OPENSSL_VERSION \"${OPENSSL_VERSION}\")
set(OPENSSL_INCLUDE_DIR \"\${CMAKE_CURRENT_LIST_DIR}/../../../include\")
set(OPENSSL_LIBRARIES OpenSSL::SSL;OpenSSL::Crypto)
set(OPENSSL_CRYPTO_LIBRARIES OpenSSL::Crypto)
set(OPENSSL_SSL_LIBRARIES OpenSSL::SSL)
")
    file(WRITE "${OPENSSL_CMAKE_DIR}/OpenSSLConfig.cmake" "${CONFIG_CONTENT}")
    message(STATUS "Manually generated modern CMake files for OpenSSL.")
endfunction()

# Determine platform-specific configuration for OpenSSL
if(APPLE)
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "arm64|aarch64")
        set(_openssl_platform "darwin64-arm64-cc")
    else()
        set(_openssl_platform "darwin64-x86_64-cc")
    endif()
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(_openssl_platform "linux-x86_64")
else()
    message(FATAL_ERROR "Unsupported platform for OpenSSL: ${CMAKE_SYSTEM_NAME}")
endif()

# Define configuration options
set(_openssl_config_options
    ${_openssl_platform}
    --openssldir=${OPENSSL_INSTALL_DIR}/ssl
    no-shared
    no-tests
    no-engine
    no-deprecated
    -fPIC
)
if(NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
    list(APPEND _openssl_config_options -O3)
endif()

# Build and install OpenSSL using the generic autotools function
thirdparty_build_autotools_library(openssl
    BUILD_IN_SOURCE TRUE
    CONFIGURE_SCRIPT_NAME "Configure"
    CONFIGURE_ARGS
        ${_openssl_config_options}
    INSTALL_ARGS
        "install_sw"
    POST_INSTALL_COMMAND
        openssl_create_cmake_config
    VALIDATION_FILES
        "${OPENSSL_INSTALL_DIR}/lib/libssl.a"
        "${OPENSSL_INSTALL_DIR}/lib/libcrypto.a"
        "${OPENSSL_INSTALL_DIR}/include/openssl/ssl.h"
        "${OPENSSL_INSTALL_DIR}/lib/cmake/OpenSSL/OpenSSLConfig.cmake"
)

# Export OpenSSL following project standards
if(EXISTS "${OPENSSL_INSTALL_DIR}/lib/cmake/OpenSSL/OpenSSLConfig.cmake")
    list(APPEND CMAKE_PREFIX_PATH "${OPENSSL_INSTALL_DIR}")
    thirdparty_safe_set_parent_scope(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}")
    set(OpenSSL_DIR "${OPENSSL_INSTALL_DIR}/lib/cmake/OpenSSL" CACHE PATH "OpenSSL cmake config directory" FORCE)
    thirdparty_safe_set_parent_scope(OPENSSL_FOUND TRUE)
    
    # Import OpenSSL package immediately
    find_package(OpenSSL REQUIRED CONFIG QUIET)
    
    message(STATUS "OpenSSL found and exported globally: ${OPENSSL_INSTALL_DIR}")
else()
    message(FATAL_ERROR "OpenSSL configuration failed - missing config files")
endif()
