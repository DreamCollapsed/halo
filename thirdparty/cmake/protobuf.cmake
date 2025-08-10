# Protobuf integration for the Halo project
# This file handles downloading, building, and installing Google Protocol Buffers

thirdparty_build_cmake_library("protobuf"
    EXTRACT_PATTERN "${THIRDPARTY_SRC_DIR}/protobuf-*"
    CMAKE_ARGS
        -Dprotobuf_BUILD_TESTS=OFF
        -Dprotobuf_BUILD_EXAMPLES=OFF
        -Dprotobuf_BUILD_PROTOC_BINARIES=ON
        -Dprotobuf_BUILD_SHARED_LIBS=OFF
        -Dprotobuf_MSVC_STATIC_RUNTIME=OFF
        -Dprotobuf_WITH_ZLIB=OFF
        -Dprotobuf_DISABLE_RTTI=OFF
        -Dprotobuf_ABSL_PROVIDER=package
        -Dprotobuf_BUILD_LIBPROTOC=ON
        -Dutf8_range_ENABLE_INSTALL=ON
        -Dabsl_DIR=${THIRDPARTY_INSTALL_DIR}/abseil/lib/cmake/absl
        # Force static linking of Abseil into protobuf
        -DCMAKE_FIND_LIBRARY_SUFFIXES=.a
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/protobuf/lib/libprotobuf.a"
        "${THIRDPARTY_INSTALL_DIR}/protobuf/include/google/protobuf/message.h"
        "${THIRDPARTY_INSTALL_DIR}/protobuf/bin/protoc"
)

set(PROTOBUF_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/protobuf")
get_filename_component(PROTOBUF_INSTALL_DIR "${PROTOBUF_INSTALL_DIR}" ABSOLUTE)

if(EXISTS "${PROTOBUF_INSTALL_DIR}/lib/libprotobuf.a")
    set(UTF8_RANGE_LIB "")
    if(EXISTS "${PROTOBUF_INSTALL_DIR}/lib/libutf8_range.a")
        set(UTF8_RANGE_LIB "${PROTOBUF_INSTALL_DIR}/lib/libutf8_range.a")
    endif()
    if(EXISTS "${PROTOBUF_INSTALL_DIR}/lib/libutf8_validity.a")
        list(APPEND UTF8_RANGE_LIB "${PROTOBUF_INSTALL_DIR}/lib/libutf8_validity.a")
    endif()
    
    set(PROTOBUF_REQUIRED_ABSEIL_LIBS
        absl::strings
        absl::str_format
        absl::flat_hash_map
        absl::hash
        absl::time
        absl::civil_time
        absl::status
        absl::statusor
        absl::log_internal_message
        absl::log_internal_check_op
        absl::log_internal_conditions
        absl::raw_logging_internal
        absl::base
        absl::synchronization
        absl::stacktrace
        absl::symbolize
        absl::malloc_internal
        absl::examine_stack
        absl::failure_signal_handler
        absl::debugging_internal
        absl::demangle_internal
        absl::cord
        absl::cord_internal
        absl::cordz_functions
        absl::cordz_handle
        absl::cordz_info
        absl::cordz_sample_token
        absl::int128
        absl::throw_delegate
        absl::strerror
        absl::str_format_internal
        absl::strings_internal
        absl::string_view
    )
    
    if(NOT TARGET protobuf::libprotobuf)
        add_library(protobuf::libprotobuf STATIC IMPORTED GLOBAL)
        set_target_properties(protobuf::libprotobuf PROPERTIES
            IMPORTED_LOCATION "${PROTOBUF_INSTALL_DIR}/lib/libprotobuf.a"
            INTERFACE_INCLUDE_DIRECTORIES "${PROTOBUF_INSTALL_DIR}/include"
            INTERFACE_COMPILE_FEATURES cxx_std_17
            INTERFACE_LINK_LIBRARIES "${UTF8_RANGE_LIB};${PROTOBUF_REQUIRED_ABSEIL_LIBS}"
        )
    endif()
    
    if(NOT TARGET protobuf::libprotobuf-lite)
        add_library(protobuf::libprotobuf-lite STATIC IMPORTED GLOBAL)
        set_target_properties(protobuf::libprotobuf-lite PROPERTIES
            IMPORTED_LOCATION "${PROTOBUF_INSTALL_DIR}/lib/libprotobuf-lite.a"
            INTERFACE_INCLUDE_DIRECTORIES "${PROTOBUF_INSTALL_DIR}/include"
            INTERFACE_COMPILE_FEATURES cxx_std_17
            INTERFACE_LINK_LIBRARIES "${UTF8_RANGE_LIB};${PROTOBUF_REQUIRED_ABSEIL_LIBS}"
        )
    endif()
    
    if(NOT TARGET protobuf::protoc)
        add_executable(protobuf::protoc IMPORTED GLOBAL)
        set_target_properties(protobuf::protoc PROPERTIES
            IMPORTED_LOCATION "${PROTOBUF_INSTALL_DIR}/bin/protoc"
        )
    endif()
    
    if(NOT TARGET protobuf)
        add_library(protobuf ALIAS protobuf::libprotobuf)
    endif()
    
    if(NOT TARGET protoc)
        add_executable(protoc ALIAS protobuf::protoc)
    endif()
    
    message(STATUS "protobuf found and exported globally: ${PROTOBUF_INSTALL_DIR}")
else()
    message(FATAL_ERROR "protobuf library not found at expected location: ${PROTOBUF_INSTALL_DIR}")
endif()
