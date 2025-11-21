set(ABSEIL_VERSION "20250814.1")
set(ABSEIL_URL "https://github.com/abseil/abseil-cpp/archive/refs/tags/${ABSEIL_VERSION}.tar.gz")
set(ABSEIL_SHA256 "1692f77d1739bacf3f94337188b78583cf09bab7e420d2dc6c5605a4f86785a1")

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

set(BOOST_VERSION "1.89.0")
string(REPLACE "." "_" BOOST_VERSION_UNDERSCORE ${BOOST_VERSION})
set(BOOST_URL "https://archives.boost.io/release/${BOOST_VERSION}/source/boost_${BOOST_VERSION_UNDERSCORE}.tar.gz")
set(BOOST_SHA256 "9de758db755e8330a01d995b0a24d09798048400ac25c03fc5ea9be364b13c93")

set(BZIP2_VERSION "1.0.8")
set(BZIP2_URL "https://sourceware.org/pub/bzip2/bzip2-${BZIP2_VERSION}.tar.gz")
set(BZIP2_SHA256 "ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269")

set(CARES_VERSION "1.34.5")
set(CARES_URL "https://github.com/c-ares/c-ares/releases/download/v${CARES_VERSION}/c-ares-${CARES_VERSION}.tar.gz")
set(CARES_SHA256 "7d935790e9af081c25c495fd13c2cfcda4792983418e96358ef6e7320ee06346")

set(DOUBLE_CONVERSION_VERSION "3.3.1")
set(DOUBLE_CONVERSION_URL "https://github.com/google/double-conversion/archive/refs/tags/v${DOUBLE_CONVERSION_VERSION}.tar.gz")
set(DOUBLE_CONVERSION_SHA256 "fe54901055c71302dcdc5c3ccbe265a6c191978f3761ce1414d0895d6b0ea90e")

set(FAISS_VERSION "1.13.0")
set(FAISS_URL "https://github.com/facebookresearch/faiss/archive/refs/tags/v${FAISS_VERSION}.zip")
set(FAISS_SHA256 "fa38f21184ca935a4f5a7cd26c5dee12ebdfd5550c11982a5a5519a5cecdc382")

set(FAST_FLOAT_VERSION "8.1.0")
set(FAST_FLOAT_URL "https://github.com/fastfloat/fast_float/archive/refs/tags/v${FAST_FLOAT_VERSION}.tar.gz")
set(FAST_FLOAT_SHA256 "4bfabb5979716995090ce68dce83f88f99629bc17ae280eae79311c5340143e1")

set(FBTHRIFT_VERSION "2025.11.17.00")
set(FBTHRIFT_URL "https://github.com/facebook/fbthrift/archive/refs/tags/v${FBTHRIFT_VERSION}.zip")
set(FBTHRIFT_SHA256 "0d45e5a235859649763976a2563412e24e88956bd77f098f4358f20cc0257d49")

set(FIZZ_VERSION "2025.11.17.00")
set(FIZZ_URL "https://github.com/facebookincubator/fizz/releases/download/v${FIZZ_VERSION}/fizz-v${FIZZ_VERSION}.tar.gz")
set(FIZZ_SHA256 "ecf363068adce25e933cb94bc534e993815b4e53c9e288a98f41af60806377d4")

set(FLEX_VERSION "2.6.4")
set(FLEX_URL "https://github.com/westes/flex/releases/download/v${FLEX_VERSION}/flex-${FLEX_VERSION}.tar.gz")
set(FLEX_SHA256 "e87aae032bf07c26f85ac0ed3250998c37621d95f8bd748b31f15b33c45ee995")

set(FMT_VERSION "12.1.0")
set(FMT_URL "https://github.com/fmtlib/fmt/archive/refs/tags/${FMT_VERSION}.tar.gz")
set(FMT_SHA256 "ea7de4299689e12b6dddd392f9896f08fb0777ac7168897a244a6d6085043fea")

set(FOLLY_VERSION "2025.11.17.00")
set(FOLLY_URL "https://github.com/facebook/folly/releases/download/v${FOLLY_VERSION}/folly-v${FOLLY_VERSION}.zip")
set(FOLLY_SHA256 "6cb1c32d90927a4cb7f8173036267e2c7f190a2636ebc0443abb30b24bf2c63d")

set(GEOS_VERSION "3.11.5")
set(GEOS_URL "https://download.osgeo.org/geos/geos-${GEOS_VERSION}.tar.bz2")
set(GEOS_SHA256 "7d9432f94e2c743cca13977b1f9943dfcc9a83854578870a215fb8dd7d6f21c1")

set(GFLAGS_VERSION "2.2.2")
set(GFLAGS_URL "https://github.com/gflags/gflags/archive/refs/tags/v${GFLAGS_VERSION}.tar.gz")
set(GFLAGS_SHA256 "34af2f15cf7367513b352bdcd2493ab14ce43692d2dcd9dfc499492966c64dcf")

set(GLOG_VERSION "0.7.1")
set(GLOG_URL "https://github.com/google/glog/archive/v${GLOG_VERSION}.tar.gz")
set(GLOG_SHA256 "00e4a87e87b7e7612f519a41e491f16623b12423620006f59f5688bfd8d13b08")

set(GRPC_VERSION "1.76.0")
set(GRPC_URL "https://github.com/grpc/grpc/archive/refs/tags/v${GRPC_VERSION}.tar.gz")
set(GRPC_SHA256 "0af37b800953130b47c075b56683ee60bdc3eda3c37fc6004193f5b569758204")

set(GTEST_VERSION "1.17.0")
set(GTEST_URL "https://github.com/google/googletest/archive/refs/tags/v${GTEST_VERSION}.tar.gz")
set(GTEST_SHA256 "65fab701d9829d38cb77c14acdc431d2108bfdbf8979e40eb8ae567edf10b27c")

set(ICU4C_VERSION "78.1")
set(ICU4C_URL "https://github.com/unicode-org/icu/releases/download/release-${ICU4C_VERSION}/icu4c-${ICU4C_VERSION}-sources.tgz")
set(ICU4C_SHA256 "6217f58ca39b23127605cfc6c7e0d3475fe4b0d63157011383d716cb41617886")

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

set(LLVM_PROJECT_VERSION "21.1.6")
set(LLVM_PROJECT_URL "https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_PROJECT_VERSION}/llvm-project-${LLVM_PROJECT_VERSION}.src.tar.xz")
set(LLVM_PROJECT_SHA256 "ae67086eb04bed7ca11ab880349b5f1ab6f50e1b88cda376eaf8a845b935762b")

set(LZ4_VERSION "1.10.0")
set(LZ4_URL "https://github.com/lz4/lz4/archive/refs/tags/v${LZ4_VERSION}.tar.gz")
set(LZ4_SHA256 "537512904744b35e232912055ccf8ec66d768639ff3abe5788d90d792ec5f48b")

set(MVFST_VERSION "2025.11.17.00")
set(MVFST_URL "https://github.com/facebook/mvfst/archive/refs/tags/v${MVFST_VERSION}.zip")
set(MVFST_SHA256 "cbffada7cc769abc1088a651bc419a6d9cd12c5d03c3aa95fde352300a5b91a8")

set(OPENBLAS_VERSION "0.3.30")
set(OPENBLAS_URL "https://github.com/OpenMathLib/OpenBLAS/releases/download/v${OPENBLAS_VERSION}/OpenBLAS-${OPENBLAS_VERSION}.tar.gz")
set(OPENBLAS_SHA256 "27342cff518646afb4c2b976d809102e368957974c250a25ccc965e53063c95d")

set(OPENSSL_VERSION "1.1.1w")
string(REPLACE "." "_" OPENSSL_VERSION_UNDERSCORE ${OPENSSL_VERSION})
set(OPENSSL_URL "https://github.com/openssl/openssl/releases/download/OpenSSL_${OPENSSL_VERSION_UNDERSCORE}/openssl-${OPENSSL_VERSION}.tar.gz")
set(OPENSSL_SHA256 "cf3098950cb4d853ad95c0841f1f9c6d3dc102dccfcacd521d93925208b76ac8")

set(PROTOBUF_VERSION "33.1")
set(PROTOBUF_URL "https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/protobuf-${PROTOBUF_VERSION}.tar.gz")
set(PROTOBUF_SHA256 "fda132cb0c86400381c0af1fe98bd0f775cb566cb247cdcc105e344e00acc30e")

set(RAPIDJSON_VERSION "1.1.0")
set(RAPIDJSON_URL "https://github.com/Tencent/rapidjson.git")
set(RAPIDJSON_SHA256 "24b5e7a8b27f42fa16b96fc70aade9106cf7102f")
set(RAPIDJSON_USE_GIT ON)

set(RE2_VERSION "2025-11-05")
set(RE2_URL "https://github.com/google/re2/releases/download/${RE2_VERSION}/re2-${RE2_VERSION}.tar.gz")
set(RE2_SHA256 "87f6029d2f6de8aa023654240a03ada90e876ce9a4676e258dd01ea4c26ffd67")

set(SIMDJSON_VERSION "4.2.2")
set(SIMDJSON_URL "https://github.com/simdjson/simdjson/archive/refs/tags/v${SIMDJSON_VERSION}.zip")
set(SIMDJSON_SHA256 "cb8ab43e20420b0e26969dc45a4fa0d2829ac73f9d14d5ced2ab95e701a8415d")

set(SNAPPY_VERSION "1.2.2")
set(SNAPPY_URL "https://github.com/google/snappy/archive/refs/tags/${SNAPPY_VERSION}.tar.gz")
set(SNAPPY_SHA256 "90f74bc1fbf78a6c56b3c4a082a05103b3a56bb17bca1a27e052ea11723292dc")

set(THRIFT_VERSION "0.22.0")
set(THRIFT_URL "https://github.com/apache/thrift/archive/refs/tags/v${THRIFT_VERSION}.tar.gz")
set(THRIFT_SHA256 "c4649c5879dd56c88f1e7a1c03e0fbfcc3b2a2872fb81616bffba5aa8a225a37")

set(UTF8PROC_VERSION "2.11.1")
set(UTF8PROC_URL "https://github.com/JuliaStrings/utf8proc/releases/download/v${UTF8PROC_VERSION}/utf8proc-${UTF8PROC_VERSION}.tar.gz")
set(UTF8PROC_SHA256 "0aa41260917df1ef4724f34f314babbd48ba18963e4d5a14a1752f14ee765010")

set(WANGLE_VERSION "2025.11.17.00")
set(WANGLE_URL "https://github.com/facebook/wangle/releases/download/v${WANGLE_VERSION}/wangle-v${WANGLE_VERSION}.zip")
set(WANGLE_SHA256 "e642a896c50876e4ff2581165ab40ee7241a2fd3ce62d77e1c0caf42e94b863f")

set(XSIMD_VERSION "13.2.0")
set(XSIMD_URL "https://github.com/xtensor-stack/xsimd/archive/refs/tags/${XSIMD_VERSION}.zip")
set(XSIMD_SHA256 "3ff360dc82109b11b35389a5dfed8ac15155f356f39840dff2be2e230b935b8c")

set(XTL_VERSION "0.8.1")
set(XTL_URL "https://github.com/xtensor-stack/xtl/archive/refs/tags/${XTL_VERSION}.tar.gz")
set(XTL_SHA256 "e69a696068ccffd2b435539d583665981b6c6abed596a72832bffbe3e13e1f49")

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
