# Facebook Thrift (fbthrift) integration for Halo
# Simplified via thirdparty_build_cmake_library helper.

# jemalloc CXX flags: only set on Apple platforms to avoid header conflicts on Linux
if(APPLE)
    set(_FBTHRIFT_JEMALLOC_FLAGS "-I${THIRDPARTY_INSTALL_DIR}/jemalloc/include -include ${THIRDPARTY_INSTALL_DIR}/jemalloc/include/jemalloc_prefix_compat.h")
else()
    set(_FBTHRIFT_JEMALLOC_FLAGS "")
endif()

# Combine base libc++ + fbthrift jemalloc flags
thirdparty_combine_flags(_FBTHRIFT_COMBINED_CXX_FLAGS FRAGMENTS "${HALO_CMAKE_CXX_FLAGS_BASE}" "${_FBTHRIFT_JEMALLOC_FLAGS}" "-DGLOG_USE_GLOG_EXPORT")

thirdparty_build_cmake_library("fbthrift"
    CMAKE_ARGS
        -DFBTHRIFT_BUILD_TESTS=OFF
        -DFBTHRIFT_ENABLE_WERROR=OFF
        -DFBTHRIFT_BUILD_EXAMPLES=OFF
        -DFBTHRIFT_ENABLE_TEMPLATES=ON
        -DFBTHRIFT_USE_FOLLY_DYNAMIC=OFF

        # OpenSSL
        -DOPENSSL_ROOT_DIR=${THIRDPARTY_INSTALL_DIR}/openssl
        -DOPENSSL_INCLUDE_DIR=${THIRDPARTY_INSTALL_DIR}/openssl/include
        -DOPENSSL_SSL_LIBRARY=${THIRDPARTY_INSTALL_DIR}/openssl/lib/libssl.a
        -DOPENSSL_CRYPTO_LIBRARY=${THIRDPARTY_INSTALL_DIR}/openssl/lib/libcrypto.a

        -DCMAKE_CXX_FLAGS=${_FBTHRIFT_COMBINED_CXX_FLAGS}
    FILE_REPLACEMENTS
        thrift/compiler/ast/ast_visitor.h
        "#pragma once"
        "#pragma once\n\n#include <exception>"
        thrift/compiler/whisker/object.h
        "#pragma once"
        "#pragma once\n\n#include <exception>"
        thrift/compiler/ast/t_program.h
        "#pragma once"
        "#pragma once\n\n#include <algorithm>"
        thrift/lib/cpp2/schema/SyntaxGraph.h
        "  FieldNode(\n      const detail::Resolver& resolver,\n      const apache::thrift::type::DefinitionKey& parent,\n      std::vector<Annotation>&& annotations,\n      FieldId id,\n      PresenceQualifier presence,\n      std::string_view name,\n      std::optional<std::string_view> docBlock,\n      folly::not_null_unique_ptr<TypeRef> type,\n      std::optional<apache::thrift::type::ValueId> customDefaultId)\n      : detail::WithResolver(resolver),\n        detail::WithName(name),\n        detail::WithAnnotations(std::move(annotations)),\n        detail::WithDocBlock(docBlock),\n        parent_(parent),\n        id_(id),\n        presence_(presence),\n        type_(std::move(type)),\n        customDefaultId_(std::move(customDefaultId)) {}"
        "  FieldNode(\n      const detail::Resolver& resolver,\n      const apache::thrift::type::DefinitionKey& parent,\n      std::vector<Annotation>&& annotations,\n      FieldId id,\n      PresenceQualifier presence,\n      std::string_view name,\n      std::optional<std::string_view> docBlock,\n      folly::not_null_unique_ptr<TypeRef> type,\n      std::optional<apache::thrift::type::ValueId> customDefaultId);"
        thrift/lib/cpp2/schema/SyntaxGraph.h
        "  FunctionException(\n      const detail::Resolver& resolver,\n      FieldId id,\n      std::string_view name,\n      folly::not_null_unique_ptr<TypeRef> type,\n      std::vector<Annotation>&& annotations)\n      : detail::WithResolver(resolver),\n        detail::WithName(name),\n        detail::WithAnnotations(std::move(annotations)),\n        id_(id),\n        type_(std::move(type)) {}"
        "  FunctionException(\n      const detail::Resolver& resolver,\n      FieldId id,\n      std::string_view name,\n      folly::not_null_unique_ptr<TypeRef> type,\n      std::vector<Annotation>&& annotations);"
        thrift/lib/cpp2/schema/SyntaxGraph.h
        "  FunctionParam(\n      const detail::Resolver& resolver,\n      FieldId id,\n      std::string_view name,\n      folly::not_null_unique_ptr<TypeRef> type,\n      std::vector<Annotation>&& annotations)\n      : detail::WithResolver(resolver),\n        detail::WithName(name),\n        detail::WithAnnotations(std::move(annotations)),\n        id_(id),\n        type_(std::move(type)) {}"
        "  FunctionParam(\n      const detail::Resolver& resolver,\n      FieldId id,\n      std::string_view name,\n      folly::not_null_unique_ptr<TypeRef> type,\n      std::vector<Annotation>&& annotations);"
        thrift/lib/cpp2/schema/SyntaxGraph.h
        "  FunctionResponse(\n      std::unique_ptr<TypeRef>&& type,\n      std::optional<detail::Lazy<InteractionNode>>&& interaction,\n      SinkOrStream&& sinkOrStream)\n      : type_(std::move(type)),\n        interaction_(std::move(interaction)),\n        sinkOrStream_(std::move(sinkOrStream)) {}"
        "  FunctionResponse(\n      std::unique_ptr<TypeRef>&& type,\n      std::optional<detail::Lazy<InteractionNode>>&& interaction,\n      SinkOrStream&& sinkOrStream);"
        thrift/lib/cpp2/schema/SyntaxGraph.cpp
        "} // namespace apache::thrift::syntax_graph"
        "FieldNode::FieldNode(\n    const detail::Resolver& resolver,\n    const apache::thrift::type::DefinitionKey& parent,\n    std::vector<Annotation>&& annotations,\n    FieldId id,\n    PresenceQualifier presence,\n    std::string_view name,\n    std::optional<std::string_view> docBlock,\n    folly::not_null_unique_ptr<TypeRef> type,\n    std::optional<apache::thrift::type::ValueId> customDefaultId)\n    : detail::WithResolver(resolver),\n      detail::WithName(name),\n      detail::WithAnnotations(std::move(annotations)),\n      detail::WithDocBlock(docBlock),\n      parent_(parent),\n      id_(id),\n      presence_(presence),\n      type_(std::move(type)),\n      customDefaultId_(std::move(customDefaultId)) {}\n\nFunctionException::FunctionException(\n    const detail::Resolver& resolver,\n    FieldId id,\n    std::string_view name,\n    folly::not_null_unique_ptr<TypeRef> type,\n    std::vector<Annotation>&& annotations)\n    : detail::WithResolver(resolver),\n      detail::WithName(name),\n      detail::WithAnnotations(std::move(annotations)),\n      id_(id),\n      type_(std::move(type)) {}\n\nFunctionParam::FunctionParam(\n    const detail::Resolver& resolver,\n    FieldId id,\n    std::string_view name,\n    folly::not_null_unique_ptr<TypeRef> type,\n    std::vector<Annotation>&& annotations)\n    : detail::WithResolver(resolver),\n      detail::WithName(name),\n      detail::WithAnnotations(std::move(annotations)),\n      id_(id),\n      type_(std::move(type)) {}\n\nFunctionResponse::FunctionResponse(\n    std::unique_ptr<TypeRef>&& type,\n    std::optional<detail::Lazy<InteractionNode>>&& interaction,\n    SinkOrStream&& sinkOrStream)\n    : type_(std::move(type)),\n      interaction_(std::move(interaction)),\n      sinkOrStream_(std::move(sinkOrStream)) {}\n\n} // namespace apache::thrift::syntax_graph"
        # Fix nullability warnings in Interaction.h for macOS/clang
        thrift/lib/cpp2/async/Interaction.h
        "  InteractionOverloadPolicy* getOverloadPolicy() {"
        "  InteractionOverloadPolicy* _Nullable getOverloadPolicy() {"
        thrift/lib/cpp2/async/Interaction.h
        "      Tile& tile, concurrency::ThreadManager* tm, folly::EventBase& eb);"
        "      Tile& tile, concurrency::ThreadManager* _Nullable tm, folly::EventBase& eb);"
        thrift/lib/cpp2/async/Interaction.h
        "  TilePtr(Tile* tile, folly::Executor::KeepAlive<folly::EventBase> eb)"
        "  TilePtr(Tile* _Nullable tile, folly::Executor::KeepAlive<folly::EventBase> eb)"
        thrift/lib/cpp2/async/Interaction.h
        "  Tile* get() const { return tile_; }"
        "  Tile* _Nullable get() const { return tile_; }"
        thrift/lib/cpp2/async/Interaction.h
        "  Tile* operator->() const { return tile_; }"
        "  Tile* _Nullable operator->() const { return tile_; }"
        thrift/lib/cpp2/async/Interaction.h
        "  Tile* tile_{nullptr};"
        "  Tile* _Nullable tile_{nullptr};"
        # Fix nullability warnings in Cpp2ConnContext.h for macOS/clang
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "using ClientIdentityHook = std::function<std::unique_ptr<void, void (*)(void*)>("
        "using ClientIdentityHook = std::function<std::unique_ptr<void, void (*_Nullable)(void*)>("
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  virtual const folly::AsyncTransport* getTransport() const {"
        "  virtual const folly::AsyncTransport* _Nullable getTransport() const {"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  void* getUserData() const override { return userData_.get(); }"
        "  void* _Nullable getUserData() const override { return userData_.get(); }"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  void* setUserData(folly::erased_unique_ptr data) override {"
        "  void* _Nullable setUserData(folly::erased_unique_ptr data) override {"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  const Cpp2Worker* getWorker() const { return worker_; }"
        "  const Cpp2Worker* _Nullable getWorker() const { return worker_; }"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  const IOWorkerContext* getWorkerContext() const { return workerContext_; }"
        "  const IOWorkerContext* _Nullable getWorkerContext() const { return workerContext_; }"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  detail::ServiceInterceptorOnConnectionStorage*"
        "  detail::ServiceInterceptorOnConnectionStorage* _Nullable"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  Tile* findTile(int64_t id) {"
        "  Tile* _Nullable findTile(int64_t id) {"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  const folly::AsyncTransport* transport_;"
        "  const folly::AsyncTransport* _Nullable transport_;"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  folly::EventBaseManager* manager_;"
        "  folly::EventBaseManager* _Nullable manager_;"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  const Cpp2Worker* worker_;"
        "  const Cpp2Worker* _Nullable worker_;"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  const IOWorkerContext* workerContext_;"
        "  const IOWorkerContext* _Nullable workerContext_;"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  Tile* findTile(int64_t interactionId) const {"
        "  Tile* _Nullable findTile(int64_t interactionId) const {"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "      Cpp2ConnContext* ctx,"
        "      Cpp2ConnContext* _Nonnull ctx,"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "      apache::thrift::transport::THeader* header = nullptr,"
        "      apache::thrift::transport::THeader* _Nullable header = nullptr,"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  void setConnectionContext(Cpp2ConnContext* ctx) { ctx_ = ctx; }"
        "  void setConnectionContext(Cpp2ConnContext* _Nullable ctx) { ctx_ = ctx; }"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  const folly::SocketAddress* getPeerAddress() const override {"
        "  const folly::SocketAddress* _Nullable getPeerAddress() const override {"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  const folly::SocketAddress* getLocalAddress() const {"
        "  const folly::SocketAddress* _Nullable getLocalAddress() const {"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  folly::EventBaseManager* getEventBaseManager() override {"
        "  folly::EventBaseManager* _Nullable getEventBaseManager() override {"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  void* getUserData() const override { return ctx_->getUserData(); }"
        "  void* _Nullable getUserData() const override { return ctx_->getUserData(); }"
        # Fix fmt::join -> folly::join issue in RoundRobinRequestPile.h
        thrift/lib/cpp2/server/RoundRobinRequestPile.h
        "          fmt::join(numBucketsPerPriority, \",\"),"
        "          folly::join(\",\", numBucketsPerPriority),"
        thrift/lib/cpp2/server/RoundRobinRequestPile.h
        "          fmt::join(numMaxRequestsPerPriority, \",\"));"
        "          folly::join(\",\", numMaxRequestsPerPriority));"
        # Additional nullability annotations for constructor parameters
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "    const folly::AsyncTransport* transport,"
        "    const folly::AsyncTransport* _Nullable transport,"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "    X509* cert,"
        "    X509* _Nullable cert,"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "      const folly::SocketAddress* address,"
        "      const folly::SocketAddress* _Nullable address,"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "      const folly::AsyncTransport* transport,"
        "      const folly::AsyncTransport* _Nullable transport,"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "      folly::EventBaseManager* manager,"
        "      folly::EventBaseManager* _Nullable manager,"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "      const Cpp2Worker* worker,"
        "      const Cpp2Worker* _Nullable worker,"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "      const IOWorkerContext* workerContext,"
        "      const IOWorkerContext* _Nullable workerContext,"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "      const WorkerT* worker,"
        "      const WorkerT* _Nullable worker,"
        # Ensure ThriftStreamLog is a complete type to avoid unique_ptr destructor issues
        thrift/lib/cpp2/async/ServerStreamDetail.h
        "namespace apache::thrift {\nclass ThriftStreamLog;\n} // namespace apache::thrift\n"
        "#include <thrift/lib/cpp2/logging/ThriftStreamLog.h>\n\nnamespace apache::thrift {\nclass ThriftStreamLog;\n} // namespace apache::thrift\n"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "      const folly::SocketAddress* address = nullptr,"
        "      const folly::SocketAddress* _Nullable address = nullptr,"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "      const folly::AsyncTransport* transport = nullptr,"
        "      const folly::AsyncTransport* _Nullable transport = nullptr,"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "      folly::EventBaseManager* manager = nullptr,"
        "      folly::EventBaseManager* _Nullable manager = nullptr,"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  const folly::SocketAddress* getPeerAddress() const final {"
        "  const folly::SocketAddress* _Nullable getPeerAddress() const final {"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  void setRequestHeader(apache::thrift::transport::THeader* header) {"
        "  void setRequestHeader(apache::thrift::transport::THeader* _Nullable header) {"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  virtual void* getPeerIdentities() const {"
        "  virtual void* _Nullable getPeerIdentities() const {"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  void* getAuthnIdentities() const {"
        "  void* _Nullable getAuthnIdentities() const {"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  void* setAuthnIdentities(folly::erased_unique_ptr data) {"
        "  void* _Nullable setAuthnIdentities(folly::erased_unique_ptr data) {"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  void* getRequestData() const { return requestData_.get(); }"
        "  void* _Nullable getRequestData() const { return requestData_.get(); }"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "      void* data, void (*destructor)(void*) = no_op_destructor) {"
        "      void* _Nullable data, void (*_Nullable destructor)(void* _Nullable) = no_op_destructor) {"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  virtual Cpp2ConnContext* getConnectionContext() const { return ctx_; }"
        "  virtual Cpp2ConnContext* _Nullable getConnectionContext() const { return ctx_; }"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  const std::string* clientId() const {"
        "  const std::string* _Nullable clientId() const {"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  const std::string* getClientRequestId() const {"
        "  const std::string* _Nullable getClientRequestId() const {"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  const std::string* getRoutingTarget() const {"
        "  const std::string* _Nullable getRoutingTarget() const {"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  const std::string* tenantId() const {"
        "  const std::string* _Nullable tenantId() const {"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  const syntax_graph::FunctionNode* getFunctionNode() const {"
        "  const syntax_graph::FunctionNode* _Nullable getFunctionNode() const {"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  void setFunctionNode(const syntax_graph::FunctionNode* functionNode) {"
        "  void setFunctionNode(const syntax_graph::FunctionNode* _Nullable functionNode) {"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  detail::ServiceInterceptorOnRequestStorage*"
        "  detail::ServiceInterceptorOnRequestStorage* _Nullable"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  const InterceptorFrameworkMetadataStorage* getInterceptorFrameworkMetadata() {"
        "  const InterceptorFrameworkMetadataStorage* _Nullable getInterceptorFrameworkMetadata() {"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  Cpp2ConnContext* ctx_;"
        "  Cpp2ConnContext* _Nullable ctx_;"
        thrift/lib/cpp2/server/Cpp2ConnContext.h
        "  const syntax_graph::FunctionNode* functionNode_{nullptr};"
        "  const syntax_graph::FunctionNode* _Nullable functionNode_{nullptr};"
    VALIDATION_FILES
        ${THIRDPARTY_INSTALL_DIR}/fbthrift/lib/libthriftcpp2.a
        ${THIRDPARTY_INSTALL_DIR}/fbthrift/include/thrift/lib/cpp2/Thrift.h
)

# Fix std::bind_front incompatibility with libstdc++ on Linux
# std::bind_front with member function pointers fails on some libstdc++ versions
if(NOT APPLE)
    set(_fbthrift_src_dir "${THIRDPARTY_SRC_DIR}/fbthrift")
    set(_fbthrift_fix_file "${_fbthrift_src_dir}/thrift/lib/cpp2/transport/rocket/server/detail/RocketRequestHandler.cpp")
    if(EXISTS "${_fbthrift_fix_file}")
        file(READ "${_fbthrift_fix_file}" _fbthrift_fix_content)
        string(FIND "${_fbthrift_fix_content}" "std::bind_front" _fbthrift_has_bind_front)
        if(NOT _fbthrift_has_bind_front EQUAL -1)
            string(REPLACE
                "std::bind_front(&RocketRequestHandler::shouldSample, this)"
                "[this](const apache::thrift::transport::THeader& header) { return shouldSample(header); }"
                _fbthrift_fix_content "${_fbthrift_fix_content}")
            file(WRITE "${_fbthrift_fix_file}" "${_fbthrift_fix_content}")
            message(STATUS "[fbthrift] Fixed std::bind_front incompatibility in RocketRequestHandler.cpp")
        endif()
    endif()
endif()

halo_find_package(FBThrift CONFIG REQUIRED)

thirdparty_map_imported_config(FBThrift::thriftcpp2)
