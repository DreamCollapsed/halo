# Third-party dependencies management

# Set common variables for all dependencies
set(BOOST_VERSION "1.84.0")
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

set(DOUBLE_CONVERSION_VERSION "3.3.0")
set(FMT_VERSION "10.2.1")
set(GFLAGS_VERSION "2.2.2")
set(GLOG_VERSION "0.7.0")
set(LIBEVENT_VERSION "2.1.12")
set(LIBIBERTY_VERSION "2.40")
set(LIBUNWIND_VERSION "1.7.2")
set(FOLLY_VERSION "2025.06.09.00")

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

# Boost
string(REPLACE "." "_" BOOST_VERSION_UNDERSCORE ${BOOST_VERSION})
ExternalProject_Add(boost
    URL https://boostorg.jfrog.io/artifactory/main/release/${BOOST_VERSION}/source/boost_${BOOST_VERSION_UNDERSCORE}.tar.gz
    URL_HASH SHA256=a5800f405508f5df8114558ca9855d2640a2de8f366fbb8f6a1c0641b3de3839
    PREFIX ${THIRDPARTY_BUILD_DIR}/boost
    SOURCE_DIR ${THIRDPARTY_SRC_DIR}/boost
    INSTALL_DIR ${THIRDPARTY_INSTALL_DIR}
    CONFIGURE_COMMAND ./bootstrap.sh --prefix=${THIRDPARTY_INSTALL_DIR}
    BUILD_COMMAND ./b2 install --with-atomic --with-chrono --with-context --with-date_time --with-filesystem --with-program_options --with-regex --with-system --with-thread variant=release link=static threading=multi runtime-link=shared
    BUILD_IN_SOURCE 1
    INSTALL_COMMAND ""
)

# fmt
ExternalProject_Add(fmt
    URL https://github.com/fmtlib/fmt/archive/refs/tags/${FMT_VERSION}.tar.gz
    URL_HASH SHA256=1250e4cc58bf06ee631567523f7c76488c8c3a36cfa8a87339c7d558620fa3ae
    PREFIX ${THIRDPARTY_BUILD_DIR}/fmt
    SOURCE_DIR ${THIRDPARTY_SRC_DIR}/fmt
    INSTALL_DIR ${THIRDPARTY_INSTALL_DIR}
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${THIRDPARTY_INSTALL_DIR}
        -DCMAKE_BUILD_TYPE=Release
        -DFMT_TEST=OFF
        -DFMT_DOC=OFF
)

# double-conversion
ExternalProject_Add(double-conversion
    URL https://github.com/google/double-conversion/archive/v${DOUBLE_CONVERSION_VERSION}.tar.gz
    URL_HASH SHA256=2a6956ee75534d4fbf67933ab6098c0ac1eafbb098e918adf56050a833f33e7e
    PREFIX ${THIRDPARTY_BUILD_DIR}/double-conversion
    SOURCE_DIR ${THIRDPARTY_SRC_DIR}/double-conversion
    INSTALL_DIR ${THIRDPARTY_INSTALL_DIR}
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${THIRDPARTY_INSTALL_DIR}
        -DCMAKE_BUILD_TYPE=Release
        -DBUILD_TESTING=OFF
)

# gflags
ExternalProject_Add(gflags
    URL https://github.com/gflags/gflags/archive/v${GFLAGS_VERSION}.tar.gz
    URL_HASH SHA256=34af2f15cf7367513b352bdcd2493ab14ce43692d2dcd9dfc499492966c64dcf
    PREFIX ${THIRDPARTY_BUILD_DIR}/gflags
    SOURCE_DIR ${THIRDPARTY_SRC_DIR}/gflags
    INSTALL_DIR ${THIRDPARTY_INSTALL_DIR}
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${THIRDPARTY_INSTALL_DIR}
        -DCMAKE_BUILD_TYPE=Release
        -DBUILD_TESTING=OFF
        -DBUILD_SHARED_LIBS=ON
)

# glog
ExternalProject_Add(glog
    DEPENDS gflags
    URL https://github.com/google/glog/archive/v${GLOG_VERSION}.tar.gz
    URL_HASH SHA256=78285cc6530528f7925683d9e6c2c24b2283b589b80176f29d57a76e08353e3f
    PREFIX ${THIRDPARTY_BUILD_DIR}/glog
    SOURCE_DIR ${THIRDPARTY_SRC_DIR}/glog
    INSTALL_DIR ${THIRDPARTY_INSTALL_DIR}
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${THIRDPARTY_INSTALL_DIR}
        -DCMAKE_BUILD_TYPE=Release
        -DBUILD_TESTING=OFF
        -DWITH_GFLAGS=ON
        -DGFLAGS_ROOT_DIR=${THIRDPARTY_INSTALL_DIR}
)

# libevent
ExternalProject_Add(libevent
    URL https://github.com/libevent/libevent/releases/download/release-${LIBEVENT_VERSION}-stable/libevent-${LIBEVENT_VERSION}-stable.tar.gz
    URL_HASH SHA256=92e6de1be9ec176428fd2367677e61ceffc2ee1cb119035037a27d346b0403bb
    PREFIX ${THIRDPARTY_BUILD_DIR}/libevent
    SOURCE_DIR ${THIRDPARTY_SRC_DIR}/libevent
    INSTALL_DIR ${THIRDPARTY_INSTALL_DIR}
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${THIRDPARTY_INSTALL_DIR}
        -DCMAKE_BUILD_TYPE=Release
        -DEVENT__DISABLE_TESTS=ON
        -DEVENT__DISABLE_SAMPLES=ON
)

# libunwind
ExternalProject_Add(libunwind
    URL https://github.com/libunwind/libunwind/releases/download/v${LIBUNWIND_VERSION}/libunwind-${LIBUNWIND_VERSION}.tar.gz
    URL_HASH SHA256=c61359c27c2a47e5413ee0a1b84e3ac2fd837577627be88b9d476bbd0bf4c468
    PREFIX ${THIRDPARTY_BUILD_DIR}/libunwind
    SOURCE_DIR ${THIRDPARTY_SRC_DIR}/libunwind
    INSTALL_DIR ${THIRDPARTY_INSTALL_DIR}
    CONFIGURE_COMMAND autoreconf -i && ./configure --prefix=${THIRDPARTY_INSTALL_DIR}
    BUILD_IN_SOURCE 1
)

# folly
ExternalProject_Add(folly
    DEPENDS boost fmt double-conversion gflags glog libevent libunwind
    URL https://github.com/facebook/folly/releases/download/v${FOLLY_VERSION}/folly-v${FOLLY_VERSION}.tar.gz
    URL_HASH SHA256=a630594bd06643376940fdc675689a466b1e5d22ee8a5e574d41cbba789de190
    PREFIX ${THIRDPARTY_BUILD_DIR}/folly
    SOURCE_DIR ${THIRDPARTY_SRC_DIR}/folly
    INSTALL_DIR ${THIRDPARTY_INSTALL_DIR}
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${THIRDPARTY_INSTALL_DIR}
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_PREFIX_PATH=${THIRDPARTY_INSTALL_DIR}
        -DBUILD_SHARED_LIBS=ON
        -DPACKAGE_VERSION=${FOLLY_VERSION}
)
