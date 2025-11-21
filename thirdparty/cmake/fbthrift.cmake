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
        "  FieldNode(\n      const detail::Resolver& resolver,\n      const apache::thrift::type::DefinitionKey& parent,\n      std::vector<Annotation>&& annotations,\n      FieldId id,\n      PresenceQualifier presence,\n      std::string_view name,\n      folly::not_null_unique_ptr<TypeRef> type,\n      std::optional<apache::thrift::type::ValueId> customDefaultId)\n      : detail::WithResolver(resolver),\n        detail::WithName(name),\n        detail::WithAnnotations(std::move(annotations)),\n        parent_(parent),\n        id_(id),\n        presence_(presence),\n        type_(std::move(type)),\n        customDefaultId_(std::move(customDefaultId)) {}"
        "  FieldNode(\n      const detail::Resolver& resolver,\n      const apache::thrift::type::DefinitionKey& parent,\n      std::vector<Annotation>&& annotations,\n      FieldId id,\n      PresenceQualifier presence,\n      std::string_view name,\n      folly::not_null_unique_ptr<TypeRef> type,\n      std::optional<apache::thrift::type::ValueId> customDefaultId);"
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
        "FieldNode::FieldNode(\n    const detail::Resolver& resolver,\n    const apache::thrift::type::DefinitionKey& parent,\n    std::vector<Annotation>&& annotations,\n    FieldId id,\n    PresenceQualifier presence,\n    std::string_view name,\n    folly::not_null_unique_ptr<TypeRef> type,\n    std::optional<apache::thrift::type::ValueId> customDefaultId)\n    : detail::WithResolver(resolver),\n      detail::WithName(name),\n      detail::WithAnnotations(std::move(annotations)),\n      parent_(parent),\n      id_(id),\n      presence_(presence),\n      type_(std::move(type)),\n      customDefaultId_(std::move(customDefaultId)) {}\n\nFunctionException::FunctionException(\n    const detail::Resolver& resolver,\n    FieldId id,\n    std::string_view name,\n    folly::not_null_unique_ptr<TypeRef> type,\n    std::vector<Annotation>&& annotations)\n    : detail::WithResolver(resolver),\n      detail::WithName(name),\n      detail::WithAnnotations(std::move(annotations)),\n      id_(id),\n      type_(std::move(type)) {}\n\nFunctionParam::FunctionParam(\n    const detail::Resolver& resolver,\n    FieldId id,\n    std::string_view name,\n    folly::not_null_unique_ptr<TypeRef> type,\n    std::vector<Annotation>&& annotations)\n    : detail::WithResolver(resolver),\n      detail::WithName(name),\n      detail::WithAnnotations(std::move(annotations)),\n      id_(id),\n      type_(std::move(type)) {}\n\nFunctionResponse::FunctionResponse(\n    std::unique_ptr<TypeRef>&& type,\n    std::optional<detail::Lazy<InteractionNode>>&& interaction,\n    SinkOrStream&& sinkOrStream)\n    : type_(std::move(type)),\n      interaction_(std::move(interaction)),\n      sinkOrStream_(std::move(sinkOrStream)) {}\n\n} // namespace apache::thrift::syntax_graph"
    VALIDATION_FILES
        ${THIRDPARTY_INSTALL_DIR}/fbthrift/lib/libthriftcpp2.a
        ${THIRDPARTY_INSTALL_DIR}/fbthrift/include/thrift/lib/cpp2/Thrift.h
)

halo_find_package(FBThrift CONFIG REQUIRED)

thirdparty_map_imported_config(FBThrift::thriftcpp2)
