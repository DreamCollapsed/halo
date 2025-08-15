# gRPC third-party integration
# Reference: https://github.com/grpc/grpc
# We build static libraries only; disable tests, benchmarks and examples.

thirdparty_build_cmake_library("grpc"
    EXTRACT_PATTERN "${THIRDPARTY_SRC_DIR}/grpc-*"
    CMAKE_ARGS
        -DCMAKE_CXX_STANDARD=20
        -DgRPC_BUILD_TESTS=OFF
        -DgRPC_BUILD_BENCHMARKS=OFF
        -DgRPC_BUILD_CODEGEN=ON
        -DgRPC_BUILD_CSHARP_EXT=OFF
        -DgRPC_INSTALL=ON
        -DgRPC_ABSL_PROVIDER=package
        -DgRPC_PROTOBUF_PROVIDER=package
        -DgRPC_RE2_PROVIDER=package
        -DgRPC_ZLIB_PROVIDER=package
        -DgRPC_SSL_PROVIDER=package
        -DgRPC_CARES_PROVIDER=package
        -DgRPC_GFLAGS_PROVIDER=package
        -DgRPC_DEFAULT_SSL_ROOTS_FILE=ON
        -DgRPC_BUILD_GRPC_CSHARP_PLUGIN=OFF
        -DgRPC_BUILD_GRPC_NODE_PLUGIN=OFF
        -DgRPC_BUILD_GRPC_OBJECTIVE_C_PLUGIN=OFF
        -DgRPC_BUILD_GRPC_PHP_PLUGIN=OFF
        -DgRPC_BUILD_GRPC_RUBY_PLUGIN=OFF
        -DProtobuf_PROTOC_EXECUTABLE=${THIRDPARTY_INSTALL_DIR}/protobuf/bin/protoc
        -DProtobuf_INCLUDE_DIR=${THIRDPARTY_INSTALL_DIR}/protobuf/include
        -DProtobuf_LIBRARIES=${THIRDPARTY_INSTALL_DIR}/protobuf/lib/libprotobuf.a
        -Dabsl_DIR=${THIRDPARTY_INSTALL_DIR}/abseil/lib/cmake/absl
        -Dre2_DIR=${THIRDPARTY_INSTALL_DIR}/re2/lib/cmake/re2
        -DOpenSSL_ROOT_DIR=${THIRDPARTY_INSTALL_DIR}/openssl
        -DZLIB_ROOT=${THIRDPARTY_INSTALL_DIR}/zlib
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/grpc/lib/libgrpc.a"
        "${THIRDPARTY_INSTALL_DIR}/grpc/lib/libgrpc++.a"
        "${THIRDPARTY_INSTALL_DIR}/grpc/include/grpcpp/grpcpp.h"
        "${THIRDPARTY_INSTALL_DIR}/grpc/bin/grpc_cpp_plugin"
)

find_package(gRPC CONFIG REQUIRED)
message(STATUS "gRPC found and exported globally (config=${gRPC_FOUND})")
