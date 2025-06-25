# Third-party dependencies management

# Set common variables for all dependencies
set(BOOST_VERSION "1.88.0")
set(BOOST_COMPONENTS 
    atomic
    chrono
    context
    date_time
    filesystem 
    program_options
    regex
    system
    thread
)

set(DOUBLE_CONVERSION_VERSION "3.3.1")
set(FMT_VERSION "11.2.0")
set(GFLAGS_VERSION "2.2.2")
set(GLOG_VERSION "0.6.0")
set(LIBEVENT_VERSION "2.1.12")
set(LIBUNWIND_VERSION "1.7.2")
set(FOLLY_VERSION "2025.06.23.00")

# Function to download and verify file
function(download_and_verify url filename sha256)
    if(NOT EXISTS ${THIRDPARTY_DOWNLOAD_DIR}/${filename})
        message(STATUS "Downloading ${filename}")
        file(DOWNLOAD ${url} ${THIRDPARTY_DOWNLOAD_DIR}/${filename}
            EXPECTED_HASH SHA256=${sha256}
            SHOW_PROGRESS
        )
    endif()
endfunction()

include(${CMAKE_SOURCE_DIR}/thirdparty/cmake/CMakeLists.txt)

# Boost
string(REPLACE "." "_" BOOST_VERSION_UNDERSCORE ${BOOST_VERSION})
ExternalProject_Add(boost
    URL ${boost_URL}
    URL_HASH SHA256=${boost_SHA256}
    PREFIX ${THIRDPARTY_BUILD_DIR}/boost
    SOURCE_DIR ${THIRDPARTY_SRC_DIR}/boost-${BOOST_VERSION}
    INSTALL_DIR ${THIRDPARTY_INSTALL_DIR}
    CONFIGURE_COMMAND CXX=${CMAKE_CXX_COMPILER} ./bootstrap.sh --prefix=${THIRDPARTY_INSTALL_DIR} --with-toolset=clang
    BUILD_COMMAND ./b2 install toolset=clang --with-atomic --with-chrono --with-context --with-date_time --with-filesystem --with-program_options --with-regex --with-system --with-thread variant=release link=shared,static threading=multi runtime-link=shared
    BUILD_IN_SOURCE 1
    INSTALL_COMMAND ./b2 install --prefix=${THIRDPARTY_INSTALL_DIR} toolset=clang --with-atomic --with-chrono --with-context --with-date_time --with-filesystem --with-program_options --with-regex --with-system --with-thread variant=release link=shared,static threading=multi runtime-link=shared
)

# fmt
ExternalProject_Add(fmt
    URL ${fmt_URL}
    URL_HASH SHA256=${fmt_SHA256}
    PREFIX ${THIRDPARTY_BUILD_DIR}/fmt
    SOURCE_DIR ${THIRDPARTY_SRC_DIR}/fmt
    INSTALL_DIR ${THIRDPARTY_INSTALL_DIR}
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${THIRDPARTY_INSTALL_DIR}
        -DCMAKE_BUILD_TYPE=Release
        -DFMT_TEST=OFF
        -DFMT_DOC=OFF
        -DBUILD_SHARED_LIBS=ON
)

# double-conversion_static
ExternalProject_Add(double-conversion_static
    URL ${double-conversion_URL}
    URL_HASH SHA256=${double-conversion_SHA256}
    PREFIX ${THIRDPARTY_BUILD_DIR}/double-conversion_static
    SOURCE_DIR ${THIRDPARTY_SRC_DIR}/double-conversion_static
    INSTALL_DIR ${THIRDPARTY_INSTALL_DIR}
    PATCH_COMMAND ${CMAKE_COMMAND} -E echo "Patching double-conversion CMakeLists.txt" && cp ${THIRDPARTY_SRC_DIR}/double-conversion_static/CMakeLists.txt ${THIRDPARTY_SRC_DIR}/double-conversion_static/CMakeLists.txt.bak && sed -i '' "s/cmake_minimum_required.*$/cmake_minimum_required(VERSION 3.5)/" ${THIRDPARTY_SRC_DIR}/double-conversion_static/CMakeLists.txt
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${THIRDPARTY_INSTALL_DIR}
        -DCMAKE_BUILD_TYPE=Release
        -DBUILD_TESTING=OFF
        -DBUILD_SHARED_LIBS=OFF
)

# double-conversion_shared
ExternalProject_Add(double-conversion_shared
    DEPENDS double-conversion_static
    URL ${double-conversion_URL}
    URL_HASH SHA256=${double-conversion_SHA256}
    PREFIX ${THIRDPARTY_BUILD_DIR}/double-conversion_shared
    SOURCE_DIR ${THIRDPARTY_SRC_DIR}/double-conversion_shared
    INSTALL_DIR ${THIRDPARTY_INSTALL_DIR}
    PATCH_COMMAND ${CMAKE_COMMAND} -E echo "Patching double-conversion CMakeLists.txt" && cp ${THIRDPARTY_SRC_DIR}/double-conversion_shared/CMakeLists.txt ${THIRDPARTY_SRC_DIR}/double-conversion_shared/CMakeLists.txt.bak && sed -i '' "s/cmake_minimum_required.*$/cmake_minimum_required(VERSION 3.5)/" ${THIRDPARTY_SRC_DIR}/double-conversion_shared/CMakeLists.txt
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${THIRDPARTY_INSTALL_DIR}
        -DCMAKE_BUILD_TYPE=Release
        -DBUILD_TESTING=OFF
        -DBUILD_SHARED_LIBS=ON
)

# gflags
ExternalProject_Add(gflags
    URL ${gflags_URL}
    URL_HASH SHA256=${gflags_SHA256}
    PREFIX ${THIRDPARTY_BUILD_DIR}/gflags
    SOURCE_DIR ${THIRDPARTY_SRC_DIR}/gflags
    INSTALL_DIR ${THIRDPARTY_INSTALL_DIR}
    PATCH_COMMAND ${CMAKE_COMMAND} -E echo "Patching gflags CMakeLists.txt" && cp ${THIRDPARTY_SRC_DIR}/gflags/CMakeLists.txt ${THIRDPARTY_SRC_DIR}/gflags/CMakeLists.txt.bak && sed -i '' "s/cmake_minimum_required.*$/cmake_minimum_required(VERSION 3.5)/" ${THIRDPARTY_SRC_DIR}/gflags/CMakeLists.txt
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${THIRDPARTY_INSTALL_DIR}
        -DCMAKE_BUILD_TYPE=Release
        -DBUILD_TESTING=OFF
        -DBUILD_SHARED_LIBS=ON
)

# glog_shared
ExternalProject_Add(glog_shared
    DEPENDS gflags
    URL ${glog_URL}
    URL_HASH SHA256=${glog_SHA256}
    PREFIX ${THIRDPARTY_BUILD_DIR}/glog_shared
    SOURCE_DIR ${THIRDPARTY_SRC_DIR}/glog_shared
    INSTALL_DIR ${THIRDPARTY_INSTALL_DIR}
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${THIRDPARTY_INSTALL_DIR}
        -DCMAKE_BUILD_TYPE=Release
        -DBUILD_TESTING=OFF
        -DWITH_GFLAGS=ON
        -DGFLAGS_ROOT_DIR=${THIRDPARTY_INSTALL_DIR}
        -DBUILD_SHARED_LIBS=ON
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5
)

# libevent
ExternalProject_Add(libevent
    URL ${libevent_URL}
    URL_HASH SHA256=${libevent_SHA256}
    PREFIX ${THIRDPARTY_BUILD_DIR}/libevent
    SOURCE_DIR ${THIRDPARTY_SRC_DIR}/libevent
    INSTALL_DIR ${THIRDPARTY_INSTALL_DIR}
    PATCH_COMMAND ${CMAKE_COMMAND} -E echo "Patching libevent CMakeLists.txt" && cp ${THIRDPARTY_SRC_DIR}/libevent/CMakeLists.txt ${THIRDPARTY_SRC_DIR}/libevent/CMakeLists.txt.bak && sed -i '' "s/cmake_minimum_required.*$/cmake_minimum_required(VERSION 3.5)/" ${THIRDPARTY_SRC_DIR}/libevent/CMakeLists.txt
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${THIRDPARTY_INSTALL_DIR}
        -DCMAKE_BUILD_TYPE=Release
        -DEVENT__DISABLE_TESTS=ON
        -DEVENT__DISABLE_SAMPLES=ON
)

if(NOT APPLE)
# libunwind
ExternalProject_Add(libunwind
    URL "https://github.com/libunwind/libunwind/releases/download/v${LIBUNWIND_VERSION}/libunwind-${LIBUNWIND_VERSION}.tar.gz"
    URL_HASH IGNORE
    PREFIX ${THIRDPARTY_BUILD_DIR}/libunwind
    SOURCE_DIR ${THIRDPARTY_SRC_DIR}/libunwind
    INSTALL_DIR ${THIRDPARTY_INSTALL_DIR}
    CONFIGURE_COMMAND autoreconf -i && ./configure --prefix=${THIRDPARTY_INSTALL_DIR}
    BUILD_IN_SOURCE 1
    BUILD_COMMAND make
    INSTALL_COMMAND make install
)
endif()

# fast_float (header-only)
ExternalProject_Add(fast_float
    URL ${fast_float_URL}
    URL_HASH SHA256=${fast_float_SHA256}
    PREFIX ${THIRDPARTY_BUILD_DIR}/fast_float
    SOURCE_DIR ${THIRDPARTY_SRC_DIR}/fast_float
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ${CMAKE_COMMAND} -E copy_directory ${THIRDPARTY_SRC_DIR}/fast_float/include ${THIRDPARTY_INSTALL_DIR}/include
)

if(NOT APPLE)
set(FOLLY_DEPENDS boost fmt double-conversion_shared gflags glog_shared libevent libunwind fast_float)
else()
set(FOLLY_DEPENDS boost fmt double-conversion_shared gflags glog_shared libevent fast_float)
endif()

ExternalProject_Add(folly
    DEPENDS ${FOLLY_DEPENDS}
    URL ${folly_URL}
    URL_HASH SHA256=${folly_SHA256}
    PREFIX ${THIRDPARTY_BUILD_DIR}/folly
    SOURCE_DIR ${THIRDPARTY_SRC_DIR}/folly
    INSTALL_DIR ${THIRDPARTY_INSTALL_DIR}
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${THIRDPARTY_INSTALL_DIR}
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_PREFIX_PATH=${THIRDPARTY_INSTALL_DIR}
        -DBUILD_SHARED_LIBS=ON
        -DPACKAGE_VERSION=${FOLLY_VERSION}
        -DBoost_USE_STATIC_LIBS=ON
        -DFOLLY_USE_STATIC_LIBS=ON
        -DBoost_USE_MULTITHREADED=ON
        -DBoost_USE_STATIC_RUNTIME=OFF
        -DBoost_CONTEXT_LIBRARY_RELEASE=${THIRDPARTY_INSTALL_DIR}/lib/libboost_context.a
        -DBoost_CONTEXT_LIBRARY=${THIRDPARTY_INSTALL_DIR}/lib/libboost_context.a
)

# googletest
ExternalProject_Add(googletest
    URL ${googletest_URL}
    URL_HASH SHA256=${googletest_SHA256}
    PREFIX ${THIRDPARTY_BUILD_DIR}/googletest
    SOURCE_DIR ${THIRDPARTY_SRC_DIR}/googletest
    INSTALL_DIR ${THIRDPARTY_INSTALL_DIR}
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${THIRDPARTY_INSTALL_DIR}
        -DCMAKE_BUILD_TYPE=Release
        -DBUILD_GMOCK=ON
        -DBUILD_GTEST=ON
        -DBUILD_SHARED_LIBS=ON
        -DINSTALL_GTEST=ON
)
