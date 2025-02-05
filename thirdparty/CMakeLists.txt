cmake_minimum_required(VERSION 3.22)

# 设置 CMP0135 策略
if(POLICY CMP0135)
    cmake_policy(SET CMP0135 NEW)
endif()

include(ExternalProject)
include(${CMAKE_CURRENT_SOURCE_DIR}/versions.cmake)

# 设置通用的 CMAKE 参数
set(COMMON_CMAKE_ARGS
    -DCMAKE_INSTALL_PREFIX=${THIRDPARTY_INSTALL_DIR}
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
    -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
    -DCMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD}
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
)

# 定义一个函数来检查库是否已经安装
function(is_library_installed LIB_NAME RESULT_VAR)
    if(EXISTS "${THIRDPARTY_INSTALL_DIR}/lib/lib${LIB_NAME}.a" OR 
       EXISTS "${THIRDPARTY_INSTALL_DIR}/lib/lib${LIB_NAME}.dylib" OR
       EXISTS "${THIRDPARTY_INSTALL_DIR}/lib/cmake/${LIB_NAME}")
        set(${RESULT_VAR} TRUE PARENT_SCOPE)
    else()
        set(${RESULT_VAR} FALSE PARENT_SCOPE)
    endif()
endfunction()

# 下载并安装 zlib
is_library_installed(z ZLIB_INSTALLED)
if(NOT ZLIB_INSTALLED)
    ExternalProject_Add(zlib_external
        URL ${ZLIB_URL}
        URL_HASH ${ZLIB_HASH}
        DOWNLOAD_DIR ${THIRDPARTY_DOWNLOAD_DIR}
        SOURCE_DIR ${THIRDPARTY_SRC_DIR}/zlib
        DOWNLOAD_NO_PROGRESS TRUE
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
        CMAKE_ARGS ${COMMON_CMAKE_ARGS}
        TEST_COMMAND ""
    )
endif()

# 下载并安装 openssl
is_library_installed(ssl OPENSSL_INSTALLED)
if(NOT OPENSSL_INSTALLED)
    ExternalProject_Add(openssl_external
        DEPENDS zlib_external
        URL ${OPENSSL_URL}
        URL_HASH ${OPENSSL_HASH}
        DOWNLOAD_DIR ${THIRDPARTY_DOWNLOAD_DIR}
        SOURCE_DIR ${THIRDPARTY_SRC_DIR}/openssl
        DOWNLOAD_NO_PROGRESS TRUE
        CONFIGURE_COMMAND ./config --prefix=${THIRDPARTY_INSTALL_DIR} --libdir=lib no-shared
        BUILD_IN_SOURCE 1
        BUILD_COMMAND make -j${CMAKE_BUILD_PARALLEL_LEVEL}
        INSTALL_COMMAND make install_sw
        TEST_COMMAND ""
    )
endif()

# 下载并安装 libevent
is_library_installed(event LIBEVENT_INSTALLED)
if(NOT LIBEVENT_INSTALLED)
    ExternalProject_Add(libevent_external
        DEPENDS openssl_external
        URL ${LIBEVENT_URL}
        URL_HASH ${LIBEVENT_HASH}
        DOWNLOAD_DIR ${THIRDPARTY_DOWNLOAD_DIR}
        SOURCE_DIR ${THIRDPARTY_SRC_DIR}/libevent
        DOWNLOAD_NO_PROGRESS TRUE
        CMAKE_ARGS ${COMMON_CMAKE_ARGS}
            -DEVENT__DISABLE_OPENSSL=OFF
            -DEVENT__DISABLE_TESTS=ON
            -DEVENT__DISABLE_SAMPLES=ON
            -DOPENSSL_ROOT_DIR=${THIRDPARTY_INSTALL_DIR}
        TEST_COMMAND ""
    )
endif()

# macOS 不需要 libunwind，使用系统提供的
if(NOT APPLE)
    is_library_installed(unwind LIBUNWIND_INSTALLED)
    if(NOT LIBUNWIND_INSTALLED)
        ExternalProject_Add(libunwind_external
            URL ${LIBUNWIND_URL}
            URL_HASH ${LIBUNWIND_HASH}
            DOWNLOAD_DIR ${THIRDPARTY_DOWNLOAD_DIR}
            SOURCE_DIR ${THIRDPARTY_SRC_DIR}/libunwind
            DOWNLOAD_NO_PROGRESS TRUE
            CONFIGURE_COMMAND ./configure --prefix=${THIRDPARTY_INSTALL_DIR} --enable-static --disable-shared
            BUILD_IN_SOURCE 1
            BUILD_COMMAND make -j${CMAKE_BUILD_PARALLEL_LEVEL}
            TEST_COMMAND ""
        )
    endif()
endif()

# macOS 不需要 elfutils，使用系统提供的
if(NOT APPLE)
    is_library_installed(elf ELFUTILS_INSTALLED)
    if(NOT ELFUTILS_INSTALLED)
        ExternalProject_Add(elfutils_external
            URL ${ELFUTILS_URL}
            URL_HASH ${ELFUTILS_HASH}
            DOWNLOAD_DIR ${THIRDPARTY_DOWNLOAD_DIR}
            SOURCE_DIR ${THIRDPARTY_SRC_DIR}/elfutils
            DOWNLOAD_NO_PROGRESS TRUE
            CONFIGURE_COMMAND ./configure --prefix=${THIRDPARTY_INSTALL_DIR} --enable-static --disable-shared
            BUILD_IN_SOURCE 1
            BUILD_COMMAND make -j${CMAKE_BUILD_PARALLEL_LEVEL}
            TEST_COMMAND ""
        )
    endif()
endif()

# 下载并安装 fmt
is_library_installed(fmt FMT_INSTALLED)
if(NOT FMT_INSTALLED)
    ExternalProject_Add(fmt_external
        URL ${FMT_URL}
        URL_HASH ${FMT_HASH}
        DOWNLOAD_DIR ${THIRDPARTY_DOWNLOAD_DIR}
        SOURCE_DIR ${THIRDPARTY_SRC_DIR}/fmt
        DOWNLOAD_NO_PROGRESS TRUE
        CMAKE_ARGS ${COMMON_CMAKE_ARGS}
        TEST_COMMAND ""
    )
endif()

# 下载并安装 double-conversion
is_library_installed(double-conversion DOUBLE_CONVERSION_INSTALLED)
if(NOT DOUBLE_CONVERSION_INSTALLED)
    ExternalProject_Add(double_conversion_external
        URL ${DOUBLE_CONVERSION_URL}
        URL_HASH ${DOUBLE_CONVERSION_HASH}
        DOWNLOAD_DIR ${THIRDPARTY_DOWNLOAD_DIR}
        SOURCE_DIR ${THIRDPARTY_SRC_DIR}/double-conversion
        DOWNLOAD_NO_PROGRESS TRUE
        CMAKE_ARGS ${COMMON_CMAKE_ARGS}
        TEST_COMMAND ""
    )
endif()

# 下载并安装 gflags
is_library_installed(gflags GFLAGS_INSTALLED)
if(NOT GFLAGS_INSTALLED)
    ExternalProject_Add(gflags_external
        URL ${GFLAGS_URL}
        URL_HASH ${GFLAGS_HASH}
        DOWNLOAD_DIR ${THIRDPARTY_DOWNLOAD_DIR}
        SOURCE_DIR ${THIRDPARTY_SRC_DIR}/gflags
        DOWNLOAD_NO_PROGRESS TRUE
        CMAKE_ARGS ${COMMON_CMAKE_ARGS}
        TEST_COMMAND ""
    )
endif()

# 下载并安装 glog
is_library_installed(glog GLOG_INSTALLED)
if(NOT GLOG_INSTALLED)
    ExternalProject_Add(glog_external
        DEPENDS gflags_external
        URL ${GLOG_URL}
        URL_HASH ${GLOG_HASH}
        DOWNLOAD_DIR ${THIRDPARTY_DOWNLOAD_DIR}
        SOURCE_DIR ${THIRDPARTY_SRC_DIR}/glog
        DOWNLOAD_NO_PROGRESS TRUE
        CMAKE_ARGS ${COMMON_CMAKE_ARGS}
            -DWITH_GFLAGS=ON
            -Dgflags_DIR=${THIRDPARTY_INSTALL_DIR}/lib/cmake/gflags
        TEST_COMMAND ""
    )
endif()

# 下载并安装 boost
is_library_installed(boost_system BOOST_INSTALLED)
if(NOT BOOST_INSTALLED)
    ExternalProject_Add(boost_external
        URL ${BOOST_URL}
        URL_HASH ${BOOST_HASH}
        DOWNLOAD_DIR ${THIRDPARTY_DOWNLOAD_DIR}
        SOURCE_DIR ${THIRDPARTY_SRC_DIR}/boost
        DOWNLOAD_NO_PROGRESS TRUE
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ./bootstrap.sh --prefix=${THIRDPARTY_INSTALL_DIR}
        COMMAND ./b2 install 
            --prefix=${THIRDPARTY_INSTALL_DIR}
            --with-context
            --with-filesystem
            --with-program_options
            --with-regex
            --with-system
            --with-thread
            link=static
            runtime-link=static
            threading=multi
            variant=release
            cxxstd=23
            cxxflags=-fPIC
            -j8
            --layout=versioned
            --build-type=complete
        BUILD_IN_SOURCE 1
        INSTALL_COMMAND ""
        TEST_COMMAND ""
    )
endif()

# 更新 folly 的依赖项
set(FOLLY_DEPENDS fmt_external double_conversion_external gflags_external glog_external boost_external
                  openssl_external libevent_external)

# 在非 macOS 系统上添加额外的依赖
if(NOT APPLE)
    list(APPEND FOLLY_DEPENDS libunwind_external elfutils_external)
endif()

# 下载并安装 folly
is_library_installed(folly FOLLY_INSTALLED)
if(NOT FOLLY_INSTALLED)
    ExternalProject_Add(folly_external
        DEPENDS ${FOLLY_DEPENDS}
        URL ${FOLLY_URL}
        URL_HASH ${FOLLY_HASH}
        DOWNLOAD_DIR ${THIRDPARTY_DOWNLOAD_DIR}
        SOURCE_DIR ${THIRDPARTY_SRC_DIR}/folly
        DOWNLOAD_NO_PROGRESS TRUE
        CMAKE_ARGS ${COMMON_CMAKE_ARGS}
            -DCMAKE_PREFIX_PATH=${THIRDPARTY_INSTALL_DIR}
            -DBOOST_ROOT=${THIRDPARTY_INSTALL_DIR}
            -DBoost_NO_SYSTEM_PATHS=ON
            -DOPENSSL_ROOT_DIR=${THIRDPARTY_INSTALL_DIR}
            -DLIBEVENT_ROOT=${THIRDPARTY_INSTALL_DIR}
            -DBoost_USE_STATIC_LIBS=ON
            -DBoost_USE_STATIC_RUNTIME=ON
            -DBUILD_SHARED_LIBS=OFF
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON
            -DCMAKE_POLICY_DEFAULT_CMP0074=NEW
            -DCMAKE_POLICY_DEFAULT_CMP0144=NEW
            -DCMAKE_POLICY_DEFAULT_CMP0057=NEW
            -DCMAKE_POLICY_DEFAULT_CMP0167=NEW
            -DBoost_DIR=${THIRDPARTY_INSTALL_DIR}/lib/cmake/Boost-1.84.0
            -DBoost_INCLUDE_DIR=${THIRDPARTY_INSTALL_DIR}/include
            -DBoost_LIBRARY_DIRS=${THIRDPARTY_INSTALL_DIR}/lib
            -DBoost_USE_MULTITHREADED=ON
            -DBoost_USE_DEBUG_LIBS=OFF
            -DBoost_USE_RELEASE_LIBS=ON
            -DFOLLY_USE_JEMALLOC=OFF
            -DFOLLY_HAVE_LIBUNWIND=OFF
            -DFOLLY_HAVE_DWARF=OFF
            -DFOLLY_HAVE_ELF=OFF
            -DBUILD_TESTS=OFF
            -DBOOST_LIBRARYDIR=${THIRDPARTY_INSTALL_DIR}/lib
            -DBoost_CONTEXT_LIBRARY_RELEASE=${THIRDPARTY_INSTALL_DIR}/lib/libboost_context-mt-x64.a
            -DBoost_FILESYSTEM_LIBRARY_RELEASE=${THIRDPARTY_INSTALL_DIR}/lib/libboost_filesystem-mt-x64.a
            -DBoost_PROGRAM_OPTIONS_LIBRARY_RELEASE=${THIRDPARTY_INSTALL_DIR}/lib/libboost_program_options-mt-x64.a
            -DBoost_REGEX_LIBRARY_RELEASE=${THIRDPARTY_INSTALL_DIR}/lib/libboost_regex-mt-x64.a
            -DBoost_SYSTEM_LIBRARY_RELEASE=${THIRDPARTY_INSTALL_DIR}/lib/libboost_system-mt-x64.a
            -DBoost_THREAD_LIBRARY_RELEASE=${THIRDPARTY_INSTALL_DIR}/lib/libboost_thread-mt-x64.a
    )
endif() 