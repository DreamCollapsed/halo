# gRPC third-party integration
# Reference: https://github.com/grpc/grpc
# We build static libraries only; disable tests, benchmarks and examples.

thirdparty_build_cmake_library("grpc"
    EXTRACT_PATTERN "${THIRDPARTY_SRC_DIR}/grpc-*"
    CMAKE_ARGS
        -DgRPC_BUILD_TESTS=OFF
        -DgRPC_BUILD_BENCHMARKS=OFF
        -DgRPC_BUILD_CODEGEN=ON
        -DgRPC_BUILD_CSHARP_EXT=OFF
        -DgRPC_INSTALL=ON
        -DgRPC_ABSL_PROVIDER=package
        -DgRPC_PROTOBUF_PROVIDER=package
        -DgRPC_RE2_PROVIDER=package
        -DgRPC_ZLIB_PROVIDER=package
        -DZLIB_USE_STATIC_LIBS=ON
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
    FILE_REPLACEMENTS
        "src/core/credentials/transport/tls/tls_security_connector.cc"
        "absl::bind_front(&ChannelPendingVerifierRequest::OnVerifyDone, this,
                       true),"
        "[this](absl::Status status) {
          this->OnVerifyDone(true, std::move(status));
        },"
        "src/core/credentials/transport/tls/tls_security_connector.cc"
        "absl::bind_front(&ServerPendingVerifierRequest::OnVerifyDone, this, true),"
        "[this](absl::Status status) {
          this->OnVerifyDone(true, std::move(status));
        },"
        "src/core/resolver/dns/native/dns_resolver.cc"
        "absl::bind_front(&NativeClientChannelDNSResolver::OnResolved, this),"
        "[this](absl::StatusOr<std::vector<grpc_resolved_address>> addresses_or) {
          this->OnResolved(std::move(addresses_or));
        },"
        "src/core/xds/grpc/xds_certificate_provider.cc"
        "absl::bind_front(&XdsCertificateProvider::WatchStatusCallback, this))"
        "[this](std::string cert_name, bool root_being_watched, bool identity_being_watched) {
          this->WatchStatusCallback(std::move(cert_name), root_being_watched, identity_being_watched);
        })"
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/grpc/lib/libgrpc.a"
        "${THIRDPARTY_INSTALL_DIR}/grpc/lib/libgrpc++.a"
        "${THIRDPARTY_INSTALL_DIR}/grpc/include/grpcpp/grpcpp.h"
        "${THIRDPARTY_INSTALL_DIR}/grpc/bin/grpc_cpp_plugin"
)

halo_find_package(gRPC CONFIG REQUIRED)

thirdparty_map_imported_config(
    gRPC::grpc
    gRPC::grpc++
    gRPC::grpc_unsecure
    gRPC::gpr
    gRPC::address_sorting
)

set(GRPC_CPP_PLUGIN_EXECUTABLE_PATH "${THIRDPARTY_INSTALL_DIR}/grpc/bin/grpc_cpp_plugin" CACHE INTERNAL "Path to project grpc_cpp_plugin executable")
if(EXISTS "${GRPC_CPP_PLUGIN_EXECUTABLE_PATH}")
    get_filename_component(GRPC_BIN_DIR "${GRPC_CPP_PLUGIN_EXECUTABLE_PATH}" DIRECTORY)
    list(APPEND CMAKE_PROGRAM_PATH "${GRPC_BIN_DIR}")
    set(CMAKE_PROGRAM_PATH "${CMAKE_PROGRAM_PATH}" PARENT_SCOPE)
    
    # Register executable path for main project and tests
    thirdparty_register_executable_path("grpc_cpp_plugin" "${GRPC_CPP_PLUGIN_EXECUTABLE_PATH}")
else()
    message(FATAL_ERROR "gRPC tools installation not found at ${THIRDPARTY_INSTALL_DIR}/grpc")
endif()
