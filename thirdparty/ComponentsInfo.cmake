set(ABSEIL_VERSION "20260107.0")
set(ABSEIL_URL "https://github.com/abseil/abseil-cpp/archive/refs/tags/${ABSEIL_VERSION}.tar.gz")
set(ABSEIL_SHA256 "4c124408da902be896a2f368042729655709db5e3004ec99f57e3e14439bc1b2")

# set(ARROW_VERSION "21.0.0")
# set(ARROW_URL "https://github.com/apache/arrow/releases/download/apache-arrow-${ARROW_VERSION}/apache-arrow-${ARROW_VERSION}.tar.gz")
# set(ARROW_SHA256 "5d3f8db7e72fb9f65f4785b7a1634522e8d8e9657a445af53d4a34a3849857b5")

set(ARROW_VERSION "23.0.0")
set(ARROW_URL "https://github.com/apache/arrow.git")
set(ARROW_SHA256 "303d077720f17713a191d53e25a88046645fa3a4")
set(ARROW_USE_GIT ON)

set(BISON_VERSION "3.8.2")
set(BISON_URL "https://mirrors.tuna.tsinghua.edu.cn/gnu/bison/bison-${BISON_VERSION}.tar.gz")
set(BISON_SHA256 "06c9e13bdf7eb24d4ceb6b59205a4f67c2c7e7213119644430fe82fbd14a0abb")

set(BOOST_VERSION "1.90.0")
string(REPLACE "." "_" BOOST_VERSION_UNDERSCORE ${BOOST_VERSION})
set(BOOST_URL "https://archives.boost.io/release/${BOOST_VERSION}/source/boost_${BOOST_VERSION_UNDERSCORE}.tar.gz")
set(BOOST_SHA256 "5e93d582aff26868d581a52ae78c7d8edf3f3064742c6e77901a1f18a437eea9")

set(BZIP2_VERSION "1.0.8")
set(BZIP2_URL "https://sourceware.org/pub/bzip2/bzip2-${BZIP2_VERSION}.tar.gz")
set(BZIP2_SHA256 "ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269")

set(CARES_VERSION "1.34.6")
set(CARES_URL "https://github.com/c-ares/c-ares/releases/download/v${CARES_VERSION}/c-ares-${CARES_VERSION}.tar.gz")
set(CARES_SHA256 "912dd7cc3b3e8a79c52fd7fb9c0f4ecf0aaa73e45efda880266a2d6e26b84ef5")

set(DOUBLE_CONVERSION_VERSION "3.4.0")
set(DOUBLE_CONVERSION_URL "https://github.com/google/double-conversion/archive/refs/tags/v${DOUBLE_CONVERSION_VERSION}.tar.gz")
set(DOUBLE_CONVERSION_SHA256 "42fd4d980ea86426e457b24bdfa835a6f5ad9517ddb01cdb42b99ab9c8dd5dc9")

set(FAISS_VERSION "1.13.2")
set(FAISS_URL "https://github.com/facebookresearch/faiss/archive/refs/tags/v${FAISS_VERSION}.zip")
set(FAISS_SHA256 "d2cf49a7c1cc5ac641ece59e3f7a123eea946dc628a205ca5665c19d0936967f")

set(FAST_FLOAT_VERSION "8.2.2")
set(FAST_FLOAT_URL "https://github.com/fastfloat/fast_float/archive/refs/tags/v${FAST_FLOAT_VERSION}.tar.gz")
set(FAST_FLOAT_SHA256 "e64b5fff88e04959154adbd5fb83331d91f2e04ac06454671cdfcbdff172b158")

set(FBTHRIFT_VERSION "2026.01.05.00")
set(FBTHRIFT_URL "https://github.com/facebook/fbthrift/archive/refs/tags/v${FBTHRIFT_VERSION}.zip")
set(FBTHRIFT_SHA256 "0df368e86327ee6cde4b8d8bea5247979ea653be9471b98dfcdeea71ac295830")

set(FIZZ_VERSION "2026.01.05.00")
set(FIZZ_URL "https://github.com/facebookincubator/fizz/releases/download/v${FIZZ_VERSION}/fizz-v${FIZZ_VERSION}.tar.gz")
set(FIZZ_SHA256 "4267518747d9541ba5d18c02e868020429aaa82a9c0808484a545637af000fd1")

set(FLEX_VERSION "2.6.4")
set(FLEX_URL "https://github.com/westes/flex/releases/download/v${FLEX_VERSION}/flex-${FLEX_VERSION}.tar.gz")
set(FLEX_SHA256 "e87aae032bf07c26f85ac0ed3250998c37621d95f8bd748b31f15b33c45ee995")

set(FMT_VERSION "12.1.0")
set(FMT_URL "https://github.com/fmtlib/fmt/archive/refs/tags/${FMT_VERSION}.tar.gz")
set(FMT_SHA256 "ea7de4299689e12b6dddd392f9896f08fb0777ac7168897a244a6d6085043fea")

set(FOLLY_VERSION "2026.01.05.00")
set(FOLLY_URL "https://github.com/facebook/folly/releases/download/v${FOLLY_VERSION}/folly-v${FOLLY_VERSION}.zip")
set(FOLLY_SHA256 "bc870c451042724d14f3f89e646a6d82ce7bae356cee150619c90ce6c735f7a0")

set(GEOS_VERSION "3.11.5")
set(GEOS_URL "https://download.osgeo.org/geos/geos-${GEOS_VERSION}.tar.bz2")
set(GEOS_SHA256 "7d9432f94e2c743cca13977b1f9943dfcc9a83854578870a215fb8dd7d6f21c1")

set(GFLAGS_VERSION "2.3.0")
set(GFLAGS_URL "https://github.com/gflags/gflags/archive/refs/tags/v${GFLAGS_VERSION}.tar.gz")
set(GFLAGS_SHA256 "f619a51371f41c0ad6837b2a98af9d4643b3371015d873887f7e8d3237320b2f")

set(GLOG_VERSION "0.7.1")
set(GLOG_URL "https://github.com/google/glog/archive/v${GLOG_VERSION}.tar.gz")
set(GLOG_SHA256 "00e4a87e87b7e7612f519a41e491f16623b12423620006f59f5688bfd8d13b08")

set(GRPC_VERSION "1.76.0")
set(GRPC_URL "https://github.com/grpc/grpc/archive/refs/tags/v${GRPC_VERSION}.tar.gz")
set(GRPC_SHA256 "0af37b800953130b47c075b56683ee60bdc3eda3c37fc6004193f5b569758204")

set(GTEST_VERSION "1.17.0")
set(GTEST_URL "https://github.com/google/googletest/archive/refs/tags/v${GTEST_VERSION}.tar.gz")
set(GTEST_SHA256 "65fab701d9829d38cb77c14acdc431d2108bfdbf8979e40eb8ae567edf10b27c")

set(ICU4C_VERSION "78.2")
set(ICU4C_URL "https://github.com/unicode-org/icu/releases/download/release-${ICU4C_VERSION}/icu4c-${ICU4C_VERSION}-sources.tgz")
set(ICU4C_SHA256 "3e99687b5c435d4b209630e2d2ebb79906c984685e78635078b672e03c89df35")

set(JEMALLOC_VERSION "5.3.0")
set(JEMALLOC_URL "https://github.com/jemalloc/jemalloc/releases/download/${JEMALLOC_VERSION}/jemalloc-${JEMALLOC_VERSION}.tar.bz2")
set(JEMALLOC_SHA256 "2db82d1e7119df3e71b7640219b6dfe84789bc0537983c3b7ac4f7189aecfeaa")

set(LIBEVENT_VERSION "2.1.12")
set(LIBEVENT_URL "https://github.com/libevent/libevent/releases/download/release-${LIBEVENT_VERSION}-stable/libevent-${LIBEVENT_VERSION}-stable.tar.gz")
set(LIBEVENT_SHA256 "92e6de1be9ec176428fd2367677e61ceffc2ee1cb119035037a27d346b0403bb")

set(LIBSODIUM_VERSION "1.0.21")
set(LIBSODIUM_URL "https://github.com/jedisct1/libsodium/releases/download/${LIBSODIUM_VERSION}-RELEASE/libsodium-${LIBSODIUM_VERSION}.tar.gz")
set(LIBSODIUM_SHA256 "9e4285c7a419e82dedb0be63a72eea357d6943bc3e28e6735bf600dd4883feaf")

set(LIBSTEMMER_VERSION "3.0.1")
set(LIBSTEMMER_URL "https://snowballstem.org/dist/libstemmer_c-${LIBSTEMMER_VERSION}.tar.gz")
set(LIBSTEMMER_SHA256 "419db89961cf2e30e6417265a4f3c903632d47d6917e7f8c6ae0e4d998743aad")

set(LLVM_PROJECT_VERSION "21.1.8")
set(LLVM_PROJECT_URL "https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_PROJECT_VERSION}/llvm-project-${LLVM_PROJECT_VERSION}.src.tar.xz")
set(LLVM_PROJECT_SHA256 "4633a23617fa31a3ea51242586ea7fb1da7140e426bd62fc164261fe036aa142")

set(LZ4_VERSION "1.10.0")
set(LZ4_URL "https://github.com/lz4/lz4/archive/refs/tags/v${LZ4_VERSION}.tar.gz")
set(LZ4_SHA256 "537512904744b35e232912055ccf8ec66d768639ff3abe5788d90d792ec5f48b")

set(MVFST_VERSION "2026.01.05.00")
set(MVFST_URL "https://github.com/facebook/mvfst/archive/refs/tags/v${MVFST_VERSION}.zip")
set(MVFST_SHA256 "32589879136f5642f3ff44ee9269fdb2be7d515587dea1e68ff871d1646138e6")

set(OPENBLAS_VERSION "0.3.30")
set(OPENBLAS_URL "https://github.com/OpenMathLib/OpenBLAS/releases/download/v${OPENBLAS_VERSION}/OpenBLAS-${OPENBLAS_VERSION}.tar.gz")
set(OPENBLAS_SHA256 "27342cff518646afb4c2b976d809102e368957974c250a25ccc965e53063c95d")

set(OPENSSL_VERSION "1.1.1w")
string(REPLACE "." "_" OPENSSL_VERSION_UNDERSCORE ${OPENSSL_VERSION})
set(OPENSSL_URL "https://github.com/openssl/openssl/releases/download/OpenSSL_${OPENSSL_VERSION_UNDERSCORE}/openssl-${OPENSSL_VERSION}.tar.gz")
set(OPENSSL_SHA256 "cf3098950cb4d853ad95c0841f1f9c6d3dc102dccfcacd521d93925208b76ac8")

set(PROTOBUF_VERSION "33.2")
set(PROTOBUF_URL "https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/protobuf-${PROTOBUF_VERSION}.tar.gz")
set(PROTOBUF_SHA256 "6b6599b54c88d75904b7471f5ca34a725fa0af92e134dd1a32d5b395aa4b4ca8")

set(RAPIDJSON_VERSION "1.1.0")
set(RAPIDJSON_URL "https://github.com/Tencent/rapidjson.git")
set(RAPIDJSON_SHA256 "24b5e7a8b27f42fa16b96fc70aade9106cf7102f")
set(RAPIDJSON_USE_GIT ON)

set(RE2_VERSION "2025-11-05")
set(RE2_URL "https://github.com/google/re2/releases/download/${RE2_VERSION}/re2-${RE2_VERSION}.tar.gz")
set(RE2_SHA256 "87f6029d2f6de8aa023654240a03ada90e876ce9a4676e258dd01ea4c26ffd67")

set(SIMDJSON_VERSION "4.2.4")
set(SIMDJSON_URL "https://github.com/simdjson/simdjson/archive/refs/tags/v${SIMDJSON_VERSION}.zip")
set(SIMDJSON_SHA256 "8c460b4f659788b5750305c669d52dc82ab0047e0bc093a9d3d688471aebc8bb")

set(SNAPPY_VERSION "1.2.2")
set(SNAPPY_URL "https://github.com/google/snappy/archive/refs/tags/${SNAPPY_VERSION}.tar.gz")
set(SNAPPY_SHA256 "90f74bc1fbf78a6c56b3c4a082a05103b3a56bb17bca1a27e052ea11723292dc")

set(THRIFT_VERSION "0.22.0")
set(THRIFT_URL "https://github.com/apache/thrift/archive/refs/tags/v${THRIFT_VERSION}.tar.gz")
set(THRIFT_SHA256 "c4649c5879dd56c88f1e7a1c03e0fbfcc3b2a2872fb81616bffba5aa8a225a37")

set(UTF8PROC_VERSION "2.11.3")
set(UTF8PROC_URL "https://github.com/JuliaStrings/utf8proc/releases/download/v${UTF8PROC_VERSION}/utf8proc-${UTF8PROC_VERSION}.tar.gz")
set(UTF8PROC_SHA256 "415189fd2c85cd6ee5ff26af500fa387de9ada1e3e316e93f7338551481d557d")

set(WANGLE_VERSION "2026.01.05.00")
set(WANGLE_URL "https://github.com/facebook/wangle/releases/download/v${WANGLE_VERSION}/wangle-v${WANGLE_VERSION}.zip")
set(WANGLE_SHA256 "5f7ea9b8341f8d88f5b2a25df692dffdd114e37b8f6ee4fe9f2acedf80537ab0")

set(XSIMD_VERSION "14.0.0")
set(XSIMD_URL "https://github.com/xtensor-stack/xsimd/archive/refs/tags/${XSIMD_VERSION}.zip")
set(XSIMD_SHA256 "97f129f830f59e036731a16af139fc8730ce49976e6115f6f76b92cc75e09e82")

set(XTL_VERSION "0.8.1")
set(XTL_URL "https://github.com/xtensor-stack/xtl/archive/refs/tags/${XTL_VERSION}.tar.gz")
set(XTL_SHA256 "e69a696068ccffd2b435539d583665981b6c6abed596a72832bffbe3e13e1f49")

set(XXHASH_VERSION "0.8.3")
set(XXHASH_URL "https://github.com/Cyan4973/xxHash/archive/refs/tags/v${XXHASH_VERSION}.tar.gz")
set(XXHASH_SHA256 "aae608dfe8213dfd05d909a57718ef82f30722c392344583d3f39050c7f29a80")

set(XZ_VERSION "5.8.2")
set(XZ_URL "https://github.com/tukaani-project/xz/releases/download/v${XZ_VERSION}/xz-${XZ_VERSION}.tar.gz")
set(XZ_SHA256 "ce09c50a5962786b83e5da389c90dd2c15ecd0980a258dd01f70f9e7ce58a8f1")

set(ZLIB_VERSION "1.3.1")
set(ZLIB_URL "https://github.com/madler/zlib/releases/download/v${ZLIB_VERSION}/zlib-${ZLIB_VERSION}.tar.gz")
set(ZLIB_SHA256 "9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23")

set(ZSTD_VERSION "1.5.7")
set(ZSTD_URL "https://github.com/facebook/zstd/archive/refs/tags/v${ZSTD_VERSION}.tar.gz")
set(ZSTD_SHA256 "37d7284556b20954e56e1ca85b80226768902e2edabd3b649e9e72c0c9012ee3")
