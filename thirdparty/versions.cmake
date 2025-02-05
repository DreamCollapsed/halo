# 设置第三方库的版本和下载信息
set(ZLIB_VERSION "1.3.1")
set(ZLIB_URL "https://github.com/madler/zlib/archive/refs/tags/v${ZLIB_VERSION}.tar.gz")
set(ZLIB_HASH "MD5=ddb17dbbf2178807384e57ba0d81e6a1")

set(OPENSSL_VERSION "3.2.1")
set(OPENSSL_URL "https://github.com/openssl/openssl/archive/refs/tags/openssl-${OPENSSL_VERSION}.tar.gz")
set(OPENSSL_HASH "MD5=3ca6a50770f854067576e13ee33a606f")

set(LIBEVENT_VERSION "2.1.12")
set(LIBEVENT_URL "https://github.com/libevent/libevent/archive/refs/tags/release-${LIBEVENT_VERSION}-stable.tar.gz")
set(LIBEVENT_HASH "MD5=0d5a27436bf7ff8253420c8cf09f47ca")

set(FMT_VERSION "10.2.1")
set(FMT_URL "https://github.com/fmtlib/fmt/archive/refs/tags/${FMT_VERSION}.tar.gz")
set(FMT_HASH "MD5=dc09168c94f90ea890257995f2c497a5")

set(DOUBLE_CONVERSION_VERSION "3.3.0")
set(DOUBLE_CONVERSION_URL "https://github.com/google/double-conversion/archive/refs/tags/v${DOUBLE_CONVERSION_VERSION}.tar.gz")
set(DOUBLE_CONVERSION_HASH "MD5=b344abb64084a4a1d98a43e67752989b")

set(GFLAGS_VERSION "2.2.2")
set(GFLAGS_URL "https://github.com/gflags/gflags/archive/refs/tags/v${GFLAGS_VERSION}.tar.gz")
set(GFLAGS_HASH "MD5=1a865b93bacfa963201af3f75b7bd64c")

set(GLOG_VERSION "0.6.0")
set(GLOG_URL "https://github.com/google/glog/archive/refs/tags/v${GLOG_VERSION}.tar.gz")
set(GLOG_HASH "MD5=c98a6068bc9b8ad9cebaca625ca73aa2")

set(BOOST_VERSION "1.84.0")
set(BOOST_URL "https://github.com/boostorg/boost/releases/download/boost-${BOOST_VERSION}/boost-${BOOST_VERSION}.tar.gz")
set(BOOST_HASH "MD5=1a84c4e387f491dedc0ece83c64bc815")

set(FOLLY_VERSION "2024.03.11.00")
set(FOLLY_URL "https://github.com/facebook/folly/archive/refs/tags/v${FOLLY_VERSION}.tar.gz")
set(FOLLY_HASH "MD5=6e70dc0fc5bbd88e7e1ca1773c0459ef")

if(NOT APPLE)
    set(LIBUNWIND_VERSION "1.7.2")
    set(LIBUNWIND_URL "https://github.com/libunwind/libunwind/releases/download/v${LIBUNWIND_VERSION}/libunwind-${LIBUNWIND_VERSION}.tar.gz")
    set(LIBUNWIND_HASH "MD5=a18a6a24307443a8ace7a8acc2ce79fb")

    set(ELFUTILS_VERSION "0.190")
    set(ELFUTILS_URL "https://sourceware.org/elfutils/ftp/${ELFUTILS_VERSION}/elfutils-${ELFUTILS_VERSION}.tar.bz2")
    set(ELFUTILS_HASH "MD5=8e00a3a9b5f04bc1dc273ae86281d2d2")
endif() 