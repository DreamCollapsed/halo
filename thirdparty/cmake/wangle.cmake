# Wangle third-party integration
# Reference: https://github.com/facebook/wangle

thirdparty_check_dependencies("folly;fizz;openssl;gflags;glog;double-conversion;libevent;boost;fmt;jemalloc;zlib;xz;bzip2;libsodium;zstd;lz4;snappy")

# Set up directories
set(WANGLE_NAME "wangle")
set(WANGLE_DOWNLOAD_FILE "${THIRDPARTY_DOWNLOAD_DIR}/wangle-v${WANGLE_VERSION}.zip")
set(WANGLE_SOURCE_DIR "${THIRDPARTY_SRC_DIR}/${WANGLE_NAME}")
set(WANGLE_BUILD_DIR "${THIRDPARTY_BUILD_DIR}/${WANGLE_NAME}")
set(WANGLE_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/${WANGLE_NAME}")

get_filename_component(WANGLE_INSTALL_DIR "${WANGLE_INSTALL_DIR}" ABSOLUTE)

thirdparty_download_and_check("${WANGLE_URL}" "${WANGLE_DOWNLOAD_FILE}" "${WANGLE_SHA256}")

if(NOT EXISTS "${WANGLE_SOURCE_DIR}/${WANGLE_NAME}/CMakeLists.txt")
    if(EXISTS "${WANGLE_SOURCE_DIR}")
        file(REMOVE_RECURSE "${WANGLE_SOURCE_DIR}")
    endif()
    
    set(_temp_extract_dir "${THIRDPARTY_SRC_DIR}/wangle_temp_extract")
    if(EXISTS "${_temp_extract_dir}")
        file(REMOVE_RECURSE "${_temp_extract_dir}")
    endif()
    file(MAKE_DIRECTORY "${_temp_extract_dir}")
    
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E tar xf "${WANGLE_DOWNLOAD_FILE}"
        WORKING_DIRECTORY "${_temp_extract_dir}"
        RESULT_VARIABLE _extract_failed
    )
    if(_extract_failed)
        message(FATAL_ERROR "Failed to extract ${WANGLE_DOWNLOAD_FILE}")
    endif()
    
    set(_wangle_source_subdir "${_temp_extract_dir}")
    if(NOT EXISTS "${_wangle_source_subdir}/${WANGLE_NAME}/CMakeLists.txt")
        file(GLOB _extracted_contents "${_temp_extract_dir}/*")
        message(FATAL_ERROR "Wangle source directory not found. Expected: ${_wangle_source_subdir}/CMakeLists.txt. Found: ${_extracted_contents}")
    endif()
    file(RENAME "${_wangle_source_subdir}" "${WANGLE_SOURCE_DIR}")
    file(REMOVE_RECURSE "${_temp_extract_dir}")

    if(NOT EXISTS "${WANGLE_SOURCE_DIR}/${WANGLE_NAME}/CMakeLists.txt")
        message(FATAL_ERROR "CMakeLists.txt not found in extracted wangle directory: ${WANGLE_SOURCE_DIR}")
    endif()

    file(READ "${WANGLE_SOURCE_DIR}/${WANGLE_NAME}/CMakeLists.txt" _wangle_cmake_content)
    string(REPLACE "include(FBBuildOptions)" "# include(FBBuildOptions) # Disabled for open-source build" _wangle_cmake_content "${_wangle_cmake_content}")
    string(REPLACE "fb_activate_static_library_option()" "# fb_activate_static_library_option() # Disabled for open-source build" _wangle_cmake_content "${_wangle_cmake_content}")
    file(WRITE "${WANGLE_SOURCE_DIR}/${WANGLE_NAME}/CMakeLists.txt" "${_wangle_cmake_content}")
    
endif()

thirdparty_get_optimization_flags(_opt_flags COMPONENT wangle)

if(APPLE AND EXISTS "${THIRDPARTY_INSTALL_DIR}/jemalloc/include/jemalloc_prefix_compat.h")
    list(APPEND _opt_flags
        -DCMAKE_CXX_FLAGS=-I${THIRDPARTY_INSTALL_DIR}/jemalloc/include\ -include\ ${THIRDPARTY_INSTALL_DIR}/jemalloc/include/jemalloc_prefix_compat.h
    ) 
endif()

list(APPEND _opt_flags
    -DCMAKE_INSTALL_PREFIX=${WANGLE_INSTALL_DIR}

    -DCMAKE_POLICY_DEFAULT_CMP0167=OLD

    -DCMAKE_MODULE_PATH=${WANGLE_SOURCE_DIR}/build/fbcode_builder/CMake

    # FOLLY
    -Dfolly_DIR=${THIRDPARTY_INSTALL_DIR}/folly/lib/cmake/folly

    # FIZZ
    -Dfizz_DIR=${THIRDPARTY_INSTALL_DIR}/fizz/lib/cmake/fizz

    # FMT 
    -Dfmt_DIR=${THIRDPARTY_INSTALL_DIR}/fmt/lib/cmake/fmt

    # OPENSSL
    -DOPENSSL_ROOT_DIR=${THIRDPARTY_INSTALL_DIR}/openssl
    -DOPENSSL_INCLUDE_DIR=${THIRDPARTY_INSTALL_DIR}/openssl/include
    -DOPENSSL_SSL_LIBRARY=${THIRDPARTY_INSTALL_DIR}/openssl/lib/libssl.a
    -DOPENSSL_CRYPTO_LIBRARY=${THIRDPARTY_INSTALL_DIR}/openssl/lib/libcrypto.a

    # GLOG
    -DGlog_DIR=${THIRDPARTY_INSTALL_DIR}/glog/lib/cmake/glog
    -DGLOG_LIBRARYDIR=${THIRDPARTY_INSTALL_DIR}/glog/lib
    -DGLOG_INCLUDEDIR=${THIRDPARTY_INSTALL_DIR}/glog/include
    -DGLOG_LIBRARY=${THIRDPARTY_INSTALL_DIR}/glog/lib/libglog.a
    -DGLOG_INCLUDE_DIR=${THIRDPARTY_INSTALL_DIR}/glog/include

    # GFLAGS
    -Dgflags_DIR=${THIRDPARTY_INSTALL_DIR}/gflags/lib/cmake/gflags

    # DOUBLE_CONVERSION
    -DDOUBLE_CONVERSION_INCLUDE_DIR=${THIRDPARTY_INSTALL_DIR}/double-conversion/include
    -DDOUBLE_CONVERSION_LIBRARY=${THIRDPARTY_INSTALL_DIR}/double-conversion/lib/libdouble-conversion.a
    -DDOUBLE_CONVERSION_LIBRARY_DIR=${THIRDPARTY_INSTALL_DIR}/double-conversion/lib

    # LIBEVENT
    -DLIBEVENT_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/libevent/include
    -DLIBEVENT_LIB:FILEPATH=${THIRDPARTY_INSTALL_DIR}/libevent/lib/libevent.a

    # ZLIB
    -DZLIB_ROOT=${THIRDPARTY_INSTALL_DIR}/zlib
    -DZLIB_INCLUDE_DIR=${THIRDPARTY_INSTALL_DIR}/zlib/include
    -DZLIB_LIBRARY=${THIRDPARTY_INSTALL_DIR}/zlib/lib/libz.a

    # BOOST
    -DBOOST_ROOT=${THIRDPARTY_INSTALL_DIR}/boost
    -DBOOST_INCLUDEDIR=${THIRDPARTY_INSTALL_DIR}/boost/include
    -DBOOST_LIBRARYDIR=${THIRDPARTY_INSTALL_DIR}/boost/lib
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

    # JEMALLOC
    -DCMAKE_CXX_FLAGS=-I${THIRDPARTY_INSTALL_DIR}/jemalloc/include\ -include\ ${THIRDPARTY_INSTALL_DIR}/jemalloc/include/jemalloc_prefix_compat.h
)

thirdparty_cmake_configure("${WANGLE_SOURCE_DIR}/${WANGLE_NAME}" "${WANGLE_BUILD_DIR}"
    FORCE_CONFIGURE
    VALIDATION_FILES
        "${WANGLE_BUILD_DIR}/CMakeCache.txt"
        "${WANGLE_BUILD_DIR}/build.ninja"
    CMAKE_ARGS
        ${_opt_flags}
)

thirdparty_cmake_install("${WANGLE_BUILD_DIR}" "${WANGLE_INSTALL_DIR}"
    VALIDATION_FILES
        "${WANGLE_INSTALL_DIR}/lib/libwangle.a"
        "${WANGLE_INSTALL_DIR}/include/wangle/channel/Pipeline.h"
)

# Export Wangle configuration for parent scope
thirdparty_safe_set_parent_scope(WANGLE_INSTALL_DIR "${WANGLE_INSTALL_DIR}")
set(wangle_DIR "${WANGLE_INSTALL_DIR}/lib/cmake/wangle" CACHE PATH "Path to installed Wangle cmake config" FORCE)

# Import Wangle package immediately
if(EXISTS "${WANGLE_INSTALL_DIR}/lib/cmake/wangle/wangle-config.cmake")
    set(Folly_DIR "${THIRDPARTY_INSTALL_DIR}/folly/lib/cmake/folly" CACHE PATH "Path to folly cmake config" FORCE)
    set(fizz_DIR "${THIRDPARTY_INSTALL_DIR}/fizz/lib/cmake/fizz" CACHE PATH "Path to fizz cmake config" FORCE)
    set(fmt_DIR "${THIRDPARTY_INSTALL_DIR}/fmt/lib/cmake/fmt" CACHE PATH "Path to fmt cmake config" FORCE)
    find_package(wangle REQUIRED CONFIG QUIET)
    message(STATUS "Wangle found and imported: ${WANGLE_INSTALL_DIR}")
else()
    message(WARNING "Wangle cmake config not found at ${WANGLE_INSTALL_DIR}")
endif()