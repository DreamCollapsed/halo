# Optimized Fizz third-party integration based on latest release analysis
# Reference: https://github.com/facebookincubator/fizz

thirdparty_check_dependencies("folly;openssl;libsodium;jemalloc;zlib")

set(FIZZ_NAME "fizz")
set(FIZZ_DOWNLOAD_FILE "${THIRDPARTY_DOWNLOAD_DIR}/fizz-v${FIZZ_VERSION}.tar.gz")
set(FIZZ_SOURCE_DIR "${THIRDPARTY_SRC_DIR}/${FIZZ_NAME}")
set(FIZZ_BUILD_DIR "${THIRDPARTY_BUILD_DIR}/${FIZZ_NAME}")
set(FIZZ_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/${FIZZ_NAME}")

get_filename_component(FIZZ_INSTALL_DIR "${FIZZ_INSTALL_DIR}" ABSOLUTE)

thirdparty_download_and_check("${FIZZ_URL}" "${FIZZ_DOWNLOAD_FILE}" "${FIZZ_SHA256}")

if(NOT EXISTS "${FIZZ_SOURCE_DIR}/CMakeLists.txt")
    if(EXISTS "${FIZZ_SOURCE_DIR}")
        file(REMOVE_RECURSE "${FIZZ_SOURCE_DIR}")
    endif()
    
    file(MAKE_DIRECTORY "${FIZZ_SOURCE_DIR}")
    
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E tar xf "${FIZZ_DOWNLOAD_FILE}"
        WORKING_DIRECTORY "${FIZZ_SOURCE_DIR}"
        RESULT_VARIABLE _extract_failed
    )
    if(_extract_failed)
        message(FATAL_ERROR "Failed to extract ${FIZZ_DOWNLOAD_FILE}")
    endif()
    
    file(GLOB _extracted_contents "${FIZZ_SOURCE_DIR}/*")
    message(STATUS "Extracted fizz contents: ${_extracted_contents}")
    
    if(NOT EXISTS "${FIZZ_SOURCE_DIR}/${FIZZ_NAME}/CMakeLists.txt")
        message(FATAL_ERROR "CMakeLists.txt not found in extracted fizz directory: ${FIZZ_SOURCE_DIR}/${FIZZ_NAME}")
    endif()
    
    file(READ "${FIZZ_SOURCE_DIR}/${FIZZ_NAME}/CMakeLists.txt" _fizz_cmake_content)
    string(REPLACE "include(FBBuildOptions)" "# include(FBBuildOptions) # Disabled for open-source build" _fizz_cmake_content "${_fizz_cmake_content}")
    string(REPLACE "fb_activate_static_library_option()" "# fb_activate_static_library_option() # Disabled for open-source build" _fizz_cmake_content "${_fizz_cmake_content}")
    file(WRITE "${FIZZ_SOURCE_DIR}/${FIZZ_NAME}/CMakeLists.txt" "${_fizz_cmake_content}")
endif()

thirdparty_get_optimization_flags(_opt_flags COMPONENT fizz)
list(APPEND _opt_flags
    -DCMAKE_INSTALL_PREFIX=${FIZZ_INSTALL_DIR}
    
    -DCMAKE_CXX_STANDARD=20
    -DCMAKE_CXX_STANDARD_REQUIRED=ON
    -DCMAKE_POLICY_DEFAULT_CMP0167=OLD

    -DCMAKE_MODULE_PATH=${FIZZ_SOURCE_DIR}/build/fbcode_builder/CMake

    # Boost
    -DBOOST_ROOT=${THIRDPARTY_INSTALL_DIR}/boost
    -DBOOST_INCLUDEDIR=${THIRDPARTY_INSTALL_DIR}/boost/include
    -DBOOST_LIBRARYDIR=${THIRDPARTY_INSTALL_DIR}/boost/lib
    -DFOLLY_BOOST_LINK_STATIC=ON
    -DBOOST_LINK_STATIC=ON
    -DBoost_USE_STATIC_LIBS=ON
    -DBoost_USE_MULTITHREADED=ON
    -DBoost_USE_STATIC_RUNTIME=ON
    -DBoost_NO_SYSTEM_PATHS=ON

    # Sodium
    -Dsodium_USE_STATIC_LIBS=ON
    -Dsodium_DIR=${THIRDPARTY_INSTALL_DIR}/libsodium
    -Dsodium_PKG_STATIC_FOUND=TRUE
    -Dsodium_PKG_STATIC_LIBRARIES=libsodium.a
    -Dsodium_PKG_STATIC_LIBRARY_DIRS=${THIRDPARTY_INSTALL_DIR}/libsodium/lib
    -Dsodium_PKG_STATIC_INCLUDE_DIRS=${THIRDPARTY_INSTALL_DIR}/libsodium/include

    # OpenSSL
    -DOPENSSL_ROOT_DIR=${THIRDPARTY_INSTALL_DIR}/openssl
    -DOPENSSL_INCLUDE_DIR=${THIRDPARTY_INSTALL_DIR}/openssl/include
    -DOPENSSL_SSL_LIBRARY=${THIRDPARTY_INSTALL_DIR}/openssl/lib/libssl.a
    -DOPENSSL_CRYPTO_LIBRARY=${THIRDPARTY_INSTALL_DIR}/openssl/lib/libcrypto.a

    # JEMALLOC
    -DCMAKE_CXX_FLAGS=-I${THIRDPARTY_INSTALL_DIR}/jemalloc/include\ -include\ ${THIRDPARTY_INSTALL_DIR}/jemalloc/include/jemalloc_prefix_compat.h
)

thirdparty_cmake_configure("${FIZZ_SOURCE_DIR}/${FIZZ_NAME}" "${FIZZ_BUILD_DIR}"
    FORCE_CONFIGURE
    VALIDATION_FILES
        "${FIZZ_BUILD_DIR}/CMakeCache.txt"
        "${FIZZ_BUILD_DIR}/build.ninja"
    CMAKE_ARGS
        ${_opt_flags}
)

thirdparty_cmake_install("${FIZZ_BUILD_DIR}" "${FIZZ_INSTALL_DIR}"
    VALIDATION_FILES
        "${FIZZ_INSTALL_DIR}/lib/libfizz.a"
        "${FIZZ_INSTALL_DIR}/include/fizz/fizz-config.h"
)

thirdparty_safe_set_parent_scope(FIZZ_INSTALL_DIR "${FIZZ_INSTALL_DIR}")
set(fizz_DIR "${FIZZ_INSTALL_DIR}/lib/cmake/fizz" CACHE PATH "Path to installed Fizz cmake config" FORCE)

if(EXISTS "${FIZZ_INSTALL_DIR}/lib/cmake/fizz/fizz-config.cmake")
    set(CMAKE_MODULE_PATH ${FIZZ_SOURCE_DIR}/build/fbcode_builder/CMake ${CMAKE_MODULE_PATH})
    set(folly_DIR "${THIRDPARTY_INSTALL_DIR}/folly/lib/cmake/folly" CACHE PATH "Path to folly cmake config" FORCE)
    
    # Ensure Sodium variables are available for fizz-config.cmake
    set(sodium_USE_STATIC_LIBS ON)
    set(sodium_PKG_STATIC_FOUND TRUE)
    set(sodium_PKG_STATIC_LIBRARIES libsodium.a)
    set(sodium_PKG_STATIC_LIBRARY_DIRS ${THIRDPARTY_INSTALL_DIR}/libsodium/lib)
    set(sodium_PKG_STATIC_INCLUDE_DIRS ${THIRDPARTY_INSTALL_DIR}/libsodium/include)
    
    # Ensure ZLIB is properly configured for fizz-config.cmake
    set(ZLIB_FOUND TRUE)
    set(ZLIB_INCLUDE_DIRS ${THIRDPARTY_INSTALL_DIR}/zlib/include)
    set(ZLIB_LIBRARIES ${THIRDPARTY_INSTALL_DIR}/zlib/lib/libz.a)
    set(ZLIB_VERSION_STRING "1.3.1")
    
    find_package(fizz REQUIRED CONFIG QUIET)
    
    message(STATUS "Fizz found and imported: ${FIZZ_INSTALL_DIR}")
else()
    message(WARNING "Fizz cmake config not found at ${FIZZ_INSTALL_DIR}")
endif()
