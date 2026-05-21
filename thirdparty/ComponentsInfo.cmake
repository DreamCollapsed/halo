set(ABSEIL_VERSION "20260107.1")
set(ABSEIL_URL "https://github.com/abseil/abseil-cpp/archive/refs/tags/${ABSEIL_VERSION}.tar.gz")
set(ABSEIL_SHA256 "4314e2a7cbac89cac25a2f2322870f343d81579756ceff7f431803c2c9090195")

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

set(FAISS_VERSION "1.14.1")
set(FAISS_URL "https://github.com/facebookresearch/faiss/archive/refs/tags/v${FAISS_VERSION}.zip")
set(FAISS_SHA256 "4b1ae7e7a0a46385b4084f0e3945623a15fcf99d793bf44d82aae8e24f11e5f5")

set(FAST_FLOAT_VERSION "8.2.5")
set(FAST_FLOAT_URL "https://github.com/fastfloat/fast_float/archive/refs/tags/v${FAST_FLOAT_VERSION}.tar.gz")
set(FAST_FLOAT_SHA256 "17c7fb14499fcf42c3f5d143df0fbe22172e92749ec5f75ef13224005421a654")

set(FBTHRIFT_VERSION "2026.05.18.00")
set(FBTHRIFT_URL "https://github.com/facebook/fbthrift/archive/refs/tags/v${FBTHRIFT_VERSION}.zip")
set(FBTHRIFT_SHA256 "ea6271621ddfd5a152d7d83911c69345fd52fce3aaf31ad3edc7d78b38afeb65")

set(FIZZ_VERSION "2026.05.18.00")
set(FIZZ_URL "https://github.com/facebookincubator/fizz/releases/download/v${FIZZ_VERSION}/fizz-v${FIZZ_VERSION}.tar.gz")
set(FIZZ_SHA256 "63c935e00c272fd7ed173748f2bd971e0be5c3922df25c6e380b48c558dbc4e3")

set(FLEX_VERSION "2.6.4")
set(FLEX_URL "https://github.com/westes/flex/releases/download/v${FLEX_VERSION}/flex-${FLEX_VERSION}.tar.gz")
set(FLEX_SHA256 "e87aae032bf07c26f85ac0ed3250998c37621d95f8bd748b31f15b33c45ee995")

set(FMT_VERSION "12.1.0")
set(FMT_URL "https://github.com/fmtlib/fmt/archive/refs/tags/${FMT_VERSION}.tar.gz")
set(FMT_SHA256 "ea7de4299689e12b6dddd392f9896f08fb0777ac7168897a244a6d6085043fea")

set(FOLLY_VERSION "2026.05.18.00")
set(FOLLY_URL "https://github.com/facebook/folly/releases/download/v${FOLLY_VERSION}/folly-v${FOLLY_VERSION}.zip")
set(FOLLY_SHA256 "c93e8ba7c5875fe3f9297ecf42ffc62ef2a540dadda6e34de2645be13e016ed3")

set(GEOS_VERSION "3.11.5")
set(GEOS_URL "https://download.osgeo.org/geos/geos-${GEOS_VERSION}.tar.bz2")
set(GEOS_SHA256 "7d9432f94e2c743cca13977b1f9943dfcc9a83854578870a215fb8dd7d6f21c1")

set(GFLAGS_VERSION "2.3.0")
set(GFLAGS_URL "https://github.com/gflags/gflags/archive/refs/tags/v${GFLAGS_VERSION}.tar.gz")
set(GFLAGS_SHA256 "f619a51371f41c0ad6837b2a98af9d4643b3371015d873887f7e8d3237320b2f")

set(GLOG_VERSION "0.7.1")
set(GLOG_URL "https://github.com/google/glog/archive/v${GLOG_VERSION}.tar.gz")
set(GLOG_SHA256 "00e4a87e87b7e7612f519a41e491f16623b12423620006f59f5688bfd8d13b08")

set(GRPC_VERSION "1.80.0")
set(GRPC_URL "https://github.com/grpc/grpc/archive/refs/tags/v${GRPC_VERSION}.tar.gz")
set(GRPC_SHA256 "38f58596277fa632064cc0719b9ece4381c8c77461cb51e9b66ca149574b7865")

set(GTEST_VERSION "1.17.0")
set(GTEST_URL "https://github.com/google/googletest/archive/refs/tags/v${GTEST_VERSION}.tar.gz")
set(GTEST_SHA256 "65fab701d9829d38cb77c14acdc431d2108bfdbf8979e40eb8ae567edf10b27c")

set(ICU4C_VERSION "78.3")
set(ICU4C_URL "https://github.com/unicode-org/icu/releases/download/release-${ICU4C_VERSION}/icu4c-${ICU4C_VERSION}-sources.tgz")
set(ICU4C_SHA256 "3a2e7a47604ba702f345878308e6fefeca612ee895cf4a5f222e7955fabfe0c0")

set(JEMALLOC_VERSION "5.3.1")
set(JEMALLOC_URL "https://github.com/jemalloc/jemalloc/releases/download/${JEMALLOC_VERSION}/jemalloc-${JEMALLOC_VERSION}.tar.bz2")
set(JEMALLOC_SHA256 "3826bc80232f22ed5c4662f3034f799ca316e819103bdc7bb99018a421706f92")

set(LIBEVENT_VERSION "2.1.12")
set(LIBEVENT_URL "https://github.com/libevent/libevent/releases/download/release-${LIBEVENT_VERSION}-stable/libevent-${LIBEVENT_VERSION}-stable.tar.gz")
set(LIBEVENT_SHA256 "92e6de1be9ec176428fd2367677e61ceffc2ee1cb119035037a27d346b0403bb")

set(LIBSODIUM_VERSION "1.0.22")
set(LIBSODIUM_URL "https://github.com/jedisct1/libsodium/releases/download/${LIBSODIUM_VERSION}-RELEASE/libsodium-${LIBSODIUM_VERSION}.tar.gz")
set(LIBSODIUM_SHA256 "adbdd8f16149e81ac6078a03aca6fc03b592b89ef7b5ed83841c086191be3349")

set(LIBSTEMMER_VERSION "3.0.1")
set(LIBSTEMMER_URL "https://snowballstem.org/dist/libstemmer_c-${LIBSTEMMER_VERSION}.tar.gz")
set(LIBSTEMMER_SHA256 "419db89961cf2e30e6417265a4f3c903632d47d6917e7f8c6ae0e4d998743aad")

set(LLVM_PROJECT_VERSION "22.1.6")
set(LLVM_PROJECT_URL "https://github.com/llvm/llvm-project/archive/refs/tags/llvmorg-${LLVM_PROJECT_VERSION}.tar.gz")
set(LLVM_PROJECT_SHA256 "ba534c6835a5b9c2162c806e269799fe41fca952a3c25baff1afcff23841ec2b")

set(LZ4_VERSION "1.10.0")
set(LZ4_URL "https://github.com/lz4/lz4/archive/refs/tags/v${LZ4_VERSION}.tar.gz")
set(LZ4_SHA256 "537512904744b35e232912055ccf8ec66d768639ff3abe5788d90d792ec5f48b")

set(MVFST_VERSION "2026.05.18.00")
set(MVFST_URL "https://github.com/facebook/mvfst/archive/refs/tags/v${MVFST_VERSION}.zip")
set(MVFST_SHA256 "e91b23cf209f203c2f2d482ebbc2bba548c60090aa93acd76abf6b31377b64e4")

set(OPENBLAS_VERSION "0.3.33")
set(OPENBLAS_URL "https://github.com/OpenMathLib/OpenBLAS/releases/download/v${OPENBLAS_VERSION}/OpenBLAS-${OPENBLAS_VERSION}.tar.gz")
set(OPENBLAS_SHA256 "6761af1d9f5d353ab4f0b7497be2643313b36c8f31caec0144bfef198e71e6ab")

set(OPENSSL_VERSION "1.1.1w")
string(REPLACE "." "_" OPENSSL_VERSION_UNDERSCORE ${OPENSSL_VERSION})
set(OPENSSL_URL "https://github.com/openssl/openssl/releases/download/OpenSSL_${OPENSSL_VERSION_UNDERSCORE}/openssl-${OPENSSL_VERSION}.tar.gz")
set(OPENSSL_SHA256 "cf3098950cb4d853ad95c0841f1f9c6d3dc102dccfcacd521d93925208b76ac8")

set(PROTOBUF_VERSION "34.0")
set(PROTOBUF_URL "https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/protobuf-${PROTOBUF_VERSION}.tar.gz")
set(PROTOBUF_SHA256 "e540aae70d3b4f758846588768c9e39090fab880bc3233a1f42a8ab8d3781efd")

set(RAPIDJSON_VERSION "1.1.0")
set(RAPIDJSON_URL "https://github.com/Tencent/rapidjson.git")
set(RAPIDJSON_SHA256 "24b5e7a8b27f42fa16b96fc70aade9106cf7102f")
set(RAPIDJSON_USE_GIT ON)

set(RE2_VERSION "2025-11-05")
set(RE2_URL "https://github.com/google/re2/releases/download/${RE2_VERSION}/re2-${RE2_VERSION}.tar.gz")
set(RE2_SHA256 "87f6029d2f6de8aa023654240a03ada90e876ce9a4676e258dd01ea4c26ffd67")

set(SIMDJSON_VERSION "4.6.4")
set(SIMDJSON_URL "https://github.com/simdjson/simdjson/archive/refs/tags/v${SIMDJSON_VERSION}.zip")
set(SIMDJSON_SHA256 "f38463a7caa9009b2cd8c4728b1d4c0dfd4801bacd813ebc39a200d6357b7827")

set(SNAPPY_VERSION "1.2.2")
set(SNAPPY_URL "https://github.com/google/snappy/archive/refs/tags/${SNAPPY_VERSION}.tar.gz")
set(SNAPPY_SHA256 "90f74bc1fbf78a6c56b3c4a082a05103b3a56bb17bca1a27e052ea11723292dc")

set(THRIFT_VERSION "0.23.0")
set(THRIFT_URL "https://github.com/apache/thrift/archive/refs/tags/v${THRIFT_VERSION}.tar.gz")
set(THRIFT_SHA256 "087ba9517063c8252e9e7fb4e3891a9fd85e20af80e0309e2276eff16791d75c")

set(UTF8PROC_VERSION "2.11.3")
set(UTF8PROC_URL "https://github.com/JuliaStrings/utf8proc/releases/download/v${UTF8PROC_VERSION}/utf8proc-${UTF8PROC_VERSION}.tar.gz")
set(UTF8PROC_SHA256 "415189fd2c85cd6ee5ff26af500fa387de9ada1e3e316e93f7338551481d557d")

set(WANGLE_VERSION "2026.05.18.00")
set(WANGLE_URL "https://github.com/facebook/wangle/releases/download/v${WANGLE_VERSION}/wangle-v${WANGLE_VERSION}.zip")
set(WANGLE_SHA256 "b9e8c40b4e1ab9ad5639d83c2d1a6fc7a69e608059444c2d075d7b81593f3824")

set(XSIMD_VERSION "14.2.0")
set(XSIMD_URL "https://github.com/xtensor-stack/xsimd/archive/refs/tags/${XSIMD_VERSION}.zip")
set(XSIMD_SHA256 "f06571e7f51618484cdeab0bf3ef0388eb18bf5a38f488024ca1d55f9881b9b5")

set(XTL_VERSION "0.8.2")
set(XTL_URL "https://github.com/xtensor-stack/xtl/archive/refs/tags/${XTL_VERSION}.tar.gz")
set(XTL_SHA256 "8fb38d6a5856aab5740d2ccb3d791d289f648d4cc506b94a1338fe5fce100c11")

set(XXHASH_VERSION "0.8.3")
set(XXHASH_URL "https://github.com/Cyan4973/xxHash/archive/refs/tags/v${XXHASH_VERSION}.tar.gz")
set(XXHASH_SHA256 "aae608dfe8213dfd05d909a57718ef82f30722c392344583d3f39050c7f29a80")

set(XZ_VERSION "5.8.3")
set(XZ_URL "https://github.com/tukaani-project/xz/releases/download/v${XZ_VERSION}/xz-${XZ_VERSION}.tar.gz")
set(XZ_SHA256 "3d3a1b973af218114f4f889bbaa2f4c037deaae0c8e815eec381c3d546b974a0")

set(ZLIB_VERSION "1.3.2")
set(ZLIB_URL "https://github.com/madler/zlib/releases/download/v${ZLIB_VERSION}/zlib-${ZLIB_VERSION}.tar.gz")
set(ZLIB_SHA256 "bb329a0a2cd0274d05519d61c667c062e06990d72e125ee2dfa8de64f0119d16")

set(ZSTD_VERSION "1.5.7")
set(ZSTD_URL "https://github.com/facebook/zstd/archive/refs/tags/v${ZSTD_VERSION}.tar.gz")
set(ZSTD_SHA256 "37d7284556b20954e56e1ca85b80226768902e2edabd3b649e9e72c0c9012ee3")
