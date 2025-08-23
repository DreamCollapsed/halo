set(ABSEIL_VERSION "20250512.1")
set(ABSEIL_URL "https://github.com/abseil/abseil-cpp/archive/refs/tags/${ABSEIL_VERSION}.tar.gz")
set(ABSEIL_SHA256 "9b7a064305e9fd94d124ffa6cc358592eb42b5da588fb4e07d09254aa40086db")

set(ARROW_VERSION "21.0.0")
set(ARROW_URL "https://github.com/apache/arrow/releases/download/apache-arrow-${ARROW_VERSION}/apache-arrow-${ARROW_VERSION}.tar.gz")
set(ARROW_SHA256 "5d3f8db7e72fb9f65f4785b7a1634522e8d8e9657a445af53d4a34a3849857b5")

set(BISON_VERSION "3.8.2")
set(BISON_URL "http://ftp.gnu.org/gnu/bison/bison-${BISON_VERSION}.tar.gz")
set(BISON_SHA256 "06c9e13bdf7eb24d4ceb6b59205a4f67c2c7e7213119644430fe82fbd14a0abb")

set(BOOST_VERSION "1.88.0")
string(REPLACE "." "_" BOOST_VERSION_UNDERSCORE ${BOOST_VERSION})
set(BOOST_URL "https://archives.boost.io/release/${BOOST_VERSION}/source/boost_${BOOST_VERSION_UNDERSCORE}.tar.gz")
set(BOOST_SHA256 "3621533e820dcab1e8012afd583c0c73cf0f77694952b81352bf38c1488f9cb4")

set(BZIP2_VERSION "1.0.8")
set(BZIP2_URL "https://sourceware.org/pub/bzip2/bzip2-${BZIP2_VERSION}.tar.gz")
set(BZIP2_SHA256 "ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269")

set(CARES_VERSION "1.34.5")
set(CARES_URL "https://github.com/c-ares/c-ares/releases/download/v${CARES_VERSION}/c-ares-${CARES_VERSION}.tar.gz")
set(CARES_SHA256 "7d935790e9af081c25c495fd13c2cfcda4792983418e96358ef6e7320ee06346")

set(DOUBLE_CONVERSION_VERSION "3.3.1")
set(DOUBLE_CONVERSION_URL "https://github.com/google/double-conversion/archive/refs/tags/v${DOUBLE_CONVERSION_VERSION}.tar.gz")
set(DOUBLE_CONVERSION_SHA256 "fe54901055c71302dcdc5c3ccbe265a6c191978f3761ce1414d0895d6b0ea90e")

set(FAISS_VERSION "1.11.0")
set(FAISS_URL "https://github.com/facebookresearch/faiss/archive/refs/tags/v${FAISS_VERSION}.zip")
set(FAISS_SHA256 "caa0e4bbf1e3c11395bdedead2f9e1be72dd02bec5023386969f90fa51d05c19")

set(FAST_FLOAT_VERSION "8.0.2")
set(FAST_FLOAT_URL "https://github.com/fastfloat/fast_float/archive/refs/tags/v${FAST_FLOAT_VERSION}.tar.gz")
set(FAST_FLOAT_SHA256 "e14a33089712b681d74d94e2a11362643bd7d769ae8f7e7caefe955f57f7eacd")

set(FBTHRIFT_VERSION "2025.08.18.00")
set(FBTHRIFT_URL "https://github.com/facebook/fbthrift/archive/refs/tags/v${FBTHRIFT_VERSION}.zip")
set(FBTHRIFT_SHA256 "519594ecc959f139b4ddc5dfdcad88ac5fad5eaa5ea58cbc84a20b98bf77dd99")

set(FIZZ_VERSION "2025.08.04.00")
set(FIZZ_URL "https://github.com/facebookincubator/fizz/releases/download/v${FIZZ_VERSION}/fizz-v${FIZZ_VERSION}.tar.gz")
set(FIZZ_SHA256 "6ca1ea0c61de358c6e5f0b933cf69d63e602f568e855046439135172ba10f0da")

set(FLEX_VERSION "2.6.4")
set(FLEX_URL "https://github.com/westes/flex/releases/download/v${FLEX_VERSION}/flex-${FLEX_VERSION}.tar.gz")
set(FLEX_SHA256 "e87aae032bf07c26f85ac0ed3250998c37621d95f8bd748b31f15b33c45ee995")

set(FMT_VERSION "11.2.0")
set(FMT_URL "https://github.com/fmtlib/fmt/archive/refs/tags/${FMT_VERSION}.tar.gz")
set(FMT_SHA256 "bc23066d87ab3168f27cef3e97d545fa63314f5c79df5ea444d41d56f962c6af")

set(FOLLY_VERSION "2025.07.14.00")
set(FOLLY_URL "https://github.com/facebook/folly/archive/refs/tags/v${FOLLY_VERSION}.tar.gz")
set(FOLLY_SHA256 "0bcb9c2ba00fe56fb0228c9a663e5a08414f59b3430e0f9f8724af0ef6e7df56")

set(GEOS_VERSION "3.13.1")
set(GEOS_URL "https://download.osgeo.org/geos/geos-${GEOS_VERSION}.tar.bz2")
set(GEOS_SHA256 "df2c50503295f325e7c8d7b783aca8ba4773919cde984193850cf9e361dfd28c")

set(GFLAGS_VERSION "2.2.2")
set(GFLAGS_URL "https://github.com/gflags/gflags/archive/refs/tags/v${GFLAGS_VERSION}.tar.gz")
set(GFLAGS_SHA256 "34af2f15cf7367513b352bdcd2493ab14ce43692d2dcd9dfc499492966c64dcf")

set(GLOG_VERSION "0.6.0")
set(GLOG_URL "https://github.com/google/glog/archive/v${GLOG_VERSION}.tar.gz")
set(GLOG_SHA256 "8a83bf982f37bb70825df71a9709fa90ea9f4447fb3c099e1d720a439d88bad6")

set(GRPC_VERSION "1.74.1")
set(GRPC_URL "https://github.com/grpc/grpc/archive/refs/tags/v${GRPC_VERSION}.tar.gz")
set(GRPC_SHA256 "7bf97c11cf3808d650a3a025bbf9c5f922c844a590826285067765dfd055d228")

set(GTEST_VERSION "1.17.0")
set(GTEST_URL "https://github.com/google/googletest/archive/refs/tags/v${GTEST_VERSION}.tar.gz")
set(GTEST_SHA256 "65fab701d9829d38cb77c14acdc431d2108bfdbf8979e40eb8ae567edf10b27c")

set(ICU4C_VERSION "77-1")
string(REPLACE "-" "_" ICU4C_VERSION_UNDERSCORE ${ICU4C_VERSION})
set(ICU4C_URL "https://github.com/unicode-org/icu/releases/download/release-${ICU4C_VERSION}/icu4c-${ICU4C_VERSION_UNDERSCORE}-src.tgz")
set(ICU4C_SHA256 "588e431f77327c39031ffbb8843c0e3bc122c211374485fa87dc5f3faff24061")

set(JEMALLOC_VERSION "5.3.0")
set(JEMALLOC_URL "https://github.com/jemalloc/jemalloc/releases/download/${JEMALLOC_VERSION}/jemalloc-${JEMALLOC_VERSION}.tar.bz2")
set(JEMALLOC_SHA256 "2db82d1e7119df3e71b7640219b6dfe84789bc0537983c3b7ac4f7189aecfeaa")

set(LIBEVENT_VERSION "2.1.12")
set(LIBEVENT_URL "https://github.com/libevent/libevent/releases/download/release-${LIBEVENT_VERSION}-stable/libevent-${LIBEVENT_VERSION}-stable.tar.gz")
set(LIBEVENT_SHA256 "92e6de1be9ec176428fd2367677e61ceffc2ee1cb119035037a27d346b0403bb")

set(LIBSODIUM_VERSION "1.0.20")
set(LIBSODIUM_URL "https://github.com/jedisct1/libsodium/releases/download/${LIBSODIUM_VERSION}-RELEASE/libsodium-${LIBSODIUM_VERSION}.tar.gz")
set(LIBSODIUM_SHA256 "ebb65ef6ca439333c2bb41a0c1990587288da07f6c7fd07cb3a18cc18d30ce19")

set(LIBSTEMMER_VERSION "3.0.1")
set(LIBSTEMMER_URL "https://snowballstem.org/dist/libstemmer_c-${LIBSTEMMER_VERSION}.tar.gz")
set(LIBSTEMMER_SHA256 "419db89961cf2e30e6417265a4f3c903632d47d6917e7f8c6ae0e4d998743aad")

set(LIBUNWIND_VERSION "20.1.8")
set(LIBUNWIND_URL "https://github.com/llvm/llvm-project/releases/download/llvmorg-${LIBUNWIND_VERSION}/libunwind-${LIBUNWIND_VERSION}.src.tar.xz")
set(LIBUNWIND_SHA256 "0bced9d701e300f8fe6599523367e214c1f928ac559afceece58f47018e9c4a7")

set(LZ4_VERSION "1.10.0")
set(LZ4_URL "https://github.com/lz4/lz4/archive/refs/tags/v${LZ4_VERSION}.tar.gz")
set(LZ4_SHA256 "537512904744b35e232912055ccf8ec66d768639ff3abe5788d90d792ec5f48b")

set(MVFST_VERSION "2025.08.11.00")
set(MVFST_URL "https://github.com/facebook/mvfst/archive/refs/tags/v${MVFST_VERSION}.zip")
set(MVFST_SHA256 "6822b6f86a24b6f7c950a6653638f5bdb90834bf2b36d5cfef76f10900ae34c5")

set(OPENSSL_VERSION "1.1.1w")
string(REPLACE "." "_" OPENSSL_VERSION_UNDERSCORE ${OPENSSL_VERSION})
set(OPENSSL_URL "https://github.com/openssl/openssl/releases/download/OpenSSL_${OPENSSL_VERSION_UNDERSCORE}/openssl-${OPENSSL_VERSION}.tar.gz")
set(OPENSSL_SHA256 "cf3098950cb4d853ad95c0841f1f9c6d3dc102dccfcacd521d93925208b76ac8")

set(PROTOBUF_VERSION "31.1")
set(PROTOBUF_URL "https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/protobuf-${PROTOBUF_VERSION}.tar.gz")
set(PROTOBUF_SHA256 "12bfd76d27b9ac3d65c00966901609e020481b9474ef75c7ff4601ac06fa0b82")

set(RAPIDJSON_VERSION "1.1.0")
set(RAPIDJSON_URL "https://github.com/Tencent/rapidjson.git")
set(RAPIDJSON_SHA256 "24b5e7a8b27f42fa16b96fc70aade9106cf7102f")
set(RAPIDJSON_USE_GIT ON)

set(RE2_VERSION "2025-07-22")
set(RE2_URL "https://github.com/google/re2/releases/download/${RE2_VERSION}/re2-${RE2_VERSION}.tar.gz")
set(RE2_SHA256 "f54c29f1c3e13e12693e3d6d1230554df3ab3a1066b2e1f28c5330bfbf6db1e3")

set(SIMDJSON_VERSION "3.13.0")
set(SIMDJSON_URL "https://github.com/simdjson/simdjson/archive/refs/tags/v${SIMDJSON_VERSION}.zip")
set(SIMDJSON_SHA256 "72a9d9d01c57a9b1d7b7d7026041e1ca2897be6a05dbde5bd753043a10a712f4")

set(SNAPPY_VERSION "1.2.2")
set(SNAPPY_URL "https://github.com/google/snappy/archive/refs/tags/${SNAPPY_VERSION}.tar.gz")
set(SNAPPY_SHA256 "90f74bc1fbf78a6c56b3c4a082a05103b3a56bb17bca1a27e052ea11723292dc")

set(THRIFT_VERSION "0.22.0")
set(THRIFT_URL "https://github.com/apache/thrift/archive/refs/tags/v${THRIFT_VERSION}.tar.gz")
set(THRIFT_SHA256 "c4649c5879dd56c88f1e7a1c03e0fbfcc3b2a2872fb81616bffba5aa8a225a37")

set(UTF8PROC_VERSION "2.10.0")
set(UTF8PROC_URL "https://github.com/JuliaStrings/utf8proc/releases/download/v${UTF8PROC_VERSION}/utf8proc-${UTF8PROC_VERSION}.tar.gz")
set(UTF8PROC_SHA256 "276a37dc4d1dd24d7896826a579f4439d1e5fe33603add786bb083cab802e23e")

set(WANGLE_VERSION "2025.07.21.00")
set(WANGLE_URL "https://github.com/facebook/wangle/releases/download/v${WANGLE_VERSION}/wangle-v${WANGLE_VERSION}.zip")
set(WANGLE_SHA256 "900a73498f6e99c7e0fc7aa15b3f6947a8bd02f64a4a24a99380d2b7ec639310")

set(XSIMD_VERSION "13.2.0")
set(XSIMD_URL "https://github.com/xtensor-stack/xsimd/archive/refs/tags/${XSIMD_VERSION}.zip")
set(XSIMD_SHA256 "3ff360dc82109b11b35389a5dfed8ac15155f356f39840dff2be2e230b935b8c")

set(XTL_VERSION "0.8.0")
set(XTL_URL "https://github.com/xtensor-stack/xtl/archive/refs/tags/${XTL_VERSION}.tar.gz")
set(XTL_SHA256 "ee38153b7dd0ec84cee3361f5488a4e7e6ddd26392612ac8821cbc76e740273a")

set(XXHASH_VERSION "0.8.3")
set(XXHASH_URL "https://github.com/Cyan4973/xxHash/archive/refs/tags/v${XXHASH_VERSION}.tar.gz")
set(XXHASH_SHA256 "aae608dfe8213dfd05d909a57718ef82f30722c392344583d3f39050c7f29a80")

set(XZ_VERSION "5.8.1")
set(XZ_URL "https://github.com/tukaani-project/xz/releases/download/v${XZ_VERSION}/xz-${XZ_VERSION}.tar.gz")
set(XZ_SHA256 "507825b599356c10dca1cd720c9d0d0c9d5400b9de300af00e4d1ea150795543")

set(ZLIB_VERSION "1.3.1")
set(ZLIB_URL "https://github.com/madler/zlib/releases/download/v${ZLIB_VERSION}/zlib-${ZLIB_VERSION}.tar.gz")
set(ZLIB_SHA256 "9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23")

set(ZSTD_VERSION "1.5.7")
set(ZSTD_URL "https://github.com/facebook/zstd/archive/refs/tags/v${ZSTD_VERSION}.tar.gz")
set(ZSTD_SHA256 "37d7284556b20954e56e1ca85b80226768902e2edabd3b649e9e72c0c9012ee3")
