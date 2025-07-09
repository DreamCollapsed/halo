
set(BOOST_VERSION "1.88.0")
string(REPLACE "." "_" BOOST_VERSION_UNDERSCORE ${BOOST_VERSION})
set(BOOST_URL "https://archives.boost.io/release/${BOOST_VERSION}/source/boost_${BOOST_VERSION_UNDERSCORE}.tar.gz")
set(BOOST_SHA256 "3621533e820dcab1e8012afd583c0c73cf0f77694952b81352bf38c1488f9cb4")

set(FMT_VERSION "11.2.0")
set(FMT_URL "https://github.com/fmtlib/fmt/archive/refs/tags/${FMT_VERSION}.tar.gz")
set(FMT_SHA256 "bc23066d87ab3168f27cef3e97d545fa63314f5c79df5ea444d41d56f962c6af")

set(DOUBLE_CONVERSION_VERSION "3.3.1")
set(DOUBLE_CONVERSION_URL "https://github.com/google/double-conversion/archive/refs/tags/v${DOUBLE_CONVERSION_VERSION}.tar.gz")
set(DOUBLE_CONVERSION_SHA256 "fe54901055c71302dcdc5c3ccbe265a6c191978f3761ce1414d0895d6b0ea90e")

set(GFLAGS_VERSION "2.2.2")
set(GFLAGS_URL "https://github.com/gflags/gflags/archive/refs/tags/v${GFLAGS_VERSION}.tar.gz")
set(GFLAGS_SHA256 "34af2f15cf7367513b352bdcd2493ab14ce43692d2dcd9dfc499492966c64dcf")

set(GLOG_VERSION "0.6.0")
set(GLOG_URL "https://github.com/google/glog/archive/v${GLOG_VERSION}.tar.gz")
set(GLOG_SHA256 "8a83bf982f37bb70825df71a9709fa90ea9f4447fb3c099e1d720a439d88bad6")

set(LIBEVENT_VERSION "2.1.12")
set(LIBEVENT_URL "https://github.com/libevent/libevent/releases/download/release-${LIBEVENT_VERSION}-stable/libevent-${LIBEVENT_VERSION}-stable.tar.gz")
set(LIBEVENT_SHA256 "92e6de1be9ec176428fd2367677e61ceffc2ee1cb119035037a27d346b0403bb")

set(FOLLY_VERSION "2025.06.23.00")
set(FOLLY_URL "https://github.com/facebook/folly/archive/refs/tags/v${FOLLY_VERSION}.tar.gz")
set(FOLLY_SHA256 "fa4cbe9accbb4fc84b40f610a7a3c1617a2ddc55a11acf9353c8edf5fd0e5547")

set(GOOGLETEST_VERSION "1.17.0")
set(GOOGLETEST_URL "https://github.com/google/googletest/archive/refs/tags/v${GOOGLETEST_VERSION}.tar.gz")
set(GOOGLETEST_SHA256 "65fab701d9829d38cb77c14acdc431d2108bfdbf8979e40eb8ae567edf10b27c")

set(FAST_FLOAT_VERSION "8.0.2")
set(FAST_FLOAT_URL "https://github.com/fastfloat/fast_float/archive/refs/tags/v${FAST_FLOAT_VERSION}.tar.gz")
set(FAST_FLOAT_SHA256 "e14a33089712b681d74d94e2a11362643bd7d769ae8f7e7caefe955f57f7eacd")

set(JEMALLOC_VERSION "5.3.0")
set(JEMALLOC_URL "https://github.com/jemalloc/jemalloc/releases/download/${JEMALLOC_VERSION}/jemalloc-${JEMALLOC_VERSION}.tar.bz2")
set(JEMALLOC_SHA256 "2db82d1e7119df3e71b7640219b6dfe84789bc0537983c3b7ac4f7189aecfeaa")

set(ABSEIL_VERSION "20250512.1")
set(ABSEIL_URL "https://github.com/abseil/abseil-cpp/archive/refs/tags/${ABSEIL_VERSION}.tar.gz")
set(ABSEIL_SHA256 "9b7a064305e9fd94d124ffa6cc358592eb42b5da588fb4e07d09254aa40086db")
