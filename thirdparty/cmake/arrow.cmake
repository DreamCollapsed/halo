# Apache Arrow third-party integration (C++)
# Reference: https://arrow.apache.org

thirdparty_setup_directories("arrow")

set(_ARROW_EXTRA_C_AND_CXX_FLAGS "${HALO_CMAKE_CXX_FLAGS_BASE} -I${THIRDPARTY_INSTALL_DIR}/boost/include -I${THIRDPARTY_INSTALL_DIR}/abseil/include")
if(APPLE)
    # On macOS we need jemalloc prefix compatibility header to map expected symbols.
    # Include both the directory and the compatibility header for symbol remapping.
    set(_ARROW_EXTRA_C_AND_CXX_FLAGS "${_ARROW_EXTRA_C_AND_CXX_FLAGS} -I${THIRDPARTY_INSTALL_DIR}/jemalloc/include -include ${THIRDPARTY_INSTALL_DIR}/jemalloc/include/jemalloc_prefix_compat.h")
endif()

list(APPEND _opt_flags
    -DCMAKE_INSTALL_PREFIX=${ARROW_INSTALL_DIR}

    -DARROW_BUILD_SHARED=OFF
    -DARROW_BUILD_STATIC=ON
    -DARROW_CXX_FLAGS_RELEASE=-O3

    -DARROW_TESTING=ON
    -DARROW_BUILD_TESTS=OFF
    -DARROW_BUILD_EXAMPLES=OFF
    -DARROW_BUILD_BENCHMARKS=OFF
    -DARROW_BUILD_INTEGRATION=ON
    -DARROW_BUILD_UTILITIES=ON

    # Use system dependencies we already build
    -DARROW_DEPENDENCY_SOURCE=SYSTEM
    -DARROW_DEPENDENCY_USE_SHARED=OFF

    # Import base + include paths (boost, abseil) and macOS-only jemalloc compatibility header.
    -DCMAKE_CXX_FLAGS=${_ARROW_EXTRA_C_AND_CXX_FLAGS}
    -DCMAKE_C_FLAGS=${_ARROW_EXTRA_C_AND_CXX_FLAGS}

    # Boost
    -DBoost_SOURCE=SYSTEM

    # Thrift
    -DThrift_SOURCE=SYSTEM

    # Snappy
    -DARROW_WITH_SNAPPY=ON
    -DARROW_SNAPPY_USE_SHARED=OFF
    -DSNAPPY_USE_STATIC_LIBS=ON
    -DSnappy_SOURCE=SYSTEM

    # Zlib
    -DARROW_WITH_ZLIB=ON
    -DZLIB_USE_STATIC_LIBS=ON
    -DZLIB_SOURCE=SYSTEM

    # Zstd
    -DARROW_WITH_ZSTD=ON
    -DARROW_ZSTD_USE_SHARED=OFF
    -DZSTD_USE_STATIC_LIBS=ON
    -DZSTD_SOURCE=SYSTEM

    # LZ4
    -DARROW_WITH_LZ4=ON
    -DARROW_WITH_LZMA=ON
    -DARROW_LZ4_USE_SHARED=OFF
    -DLZ4_USE_STATIC_LIBS=ON
    -DLZ4_SOURCE=SYSTEM

    # BZip2
    -DARROW_WITH_BZ2=ON
    -DARROW_BZ2_USE_SHARED=OFF
    -DBZIP2_USE_STATIC_LIBS=ON
    -DBZip2_SOURCE=SYSTEM

    # OpenSSL
    -DOpenSSL_SOURCE=SYSTEM
    -DOPENSSL_ROOT_DIR=${THIRDPARTY_INSTALL_DIR}/openssl
    -DOPENSSL_INCLUDE_DIR=${THIRDPARTY_INSTALL_DIR}/openssl/include
    -DOPENSSL_SSL_LIBRARY=${THIRDPARTY_INSTALL_DIR}/openssl/lib/libssl.a
    -DOPENSSL_CRYPTO_LIBRARY=${THIRDPARTY_INSTALL_DIR}/openssl/lib/libcrypto.a

    # Jemalloc
    -DARROW_JEMALLOC=ON
    -DARROW_JEMALLOC_USE_SHARED=OFF
    -Djemalloc_SOURCE=SYSTEM
    -Djemalloc_ROOT=${THIRDPARTY_INSTALL_DIR}/jemalloc

    # Protobuf
    -DARROW_PROTOBUF_USE_SHARED=OFF

    # Arrow Components
    -DARROW_ACERO=ON
    -DARROW_DATASET=ON
    -DARROW_COMPUTE=ON
    -DARROW_CSV=ON
    -DARROW_JSON=ON
    -DARROW_FILESYSTEM=ON
    -DARROW_ORC=OFF
    -DARROW_WITH_RE2=ON
    -DARROW_WITH_UTF8PROC=ON
    -DARROW_USE_GLOG=ON
    -DARROW_WITH_GRPC=ON
    -DARROW_FUZZING=OFF
    -DARROW_HDFS=ON
    -DARROW_MIMALLOC=OFF
    -DARROW_SUBSTRAIT=ON
    -DARROW_TENSORFLOW=ON

    # Parquet
    -DARROW_PARQUET=ON
    -DPARQUET_BUILD_EXECUTABLES=ON
    -DPARQUET_REQUIRE_ENCRYPTION=ON

    # Gandiva
    -DARROW_GANDIVA=ON
    -DARROW_GANDIVA_STATIC_LIBSTDCPP=ON

    # Flight
    -DARROW_FLIGHT=ON
    -DARROW_FLIGHT_SQL=ON
    -DARROW_FLIGHT_SQL_ODBC=ON
)

thirdparty_build_cmake_library("arrow"
    SOURCE_SUBDIR "cpp"
    CMAKE_ARGS ${_opt_flags}
    FILE_REPLACEMENTS
      # Fix C++23 derived-to-base pointer conversion at BackpressureController creation
      # (AsofJoinNode* to ExecNode*). Use an explicit cast on the call site to avoid
      # incomplete-type conversion errors when AsofJoinNode is forward-declared.
      "cpp/src/arrow/acero/asof_join_node.cc"
      "/*output=*/asof_node"
      "/*output=*/(ExecNode*)asof_node"
    VALIDATION_FILES
        "${ARROW_INSTALL_DIR}/lib/libarrow.a"
        "${ARROW_INSTALL_DIR}/lib/cmake/Arrow/ArrowConfig.cmake"
)

set(_HALO_ARROW_PREV_LOG_LEVEL_SAVED FALSE)
if(DEFINED CMAKE_MESSAGE_LOG_LEVEL)
    set(_HALO_ARROW_PREV_LOG_LEVEL "${CMAKE_MESSAGE_LOG_LEVEL}")
    set(_HALO_ARROW_PREV_LOG_LEVEL_SAVED TRUE)
endif()
if(DEFINED HALO_THIRDPARTY_VERBOSE_SUPPRESS AND NOT HALO_THIRDPARTY_VERBOSE_SUPPRESS)
    # Verbose: leave as STATUS (do nothing unless a higher level was set)
    if(NOT DEFINED CMAKE_MESSAGE_LOG_LEVEL OR NOT CMAKE_MESSAGE_LOG_LEVEL STREQUAL "STATUS")
        set(CMAKE_MESSAGE_LOG_LEVEL STATUS)
    endif()
else()
    # Quiet: hide STATUS spam
    set(CMAKE_MESSAGE_LOG_LEVEL NOTICE)
endif()

find_package(Arrow CONFIG QUIET REQUIRED)
if(TARGET Arrow::arrow_static AND NOT TARGET Arrow::arrow)
    add_library(Arrow::arrow ALIAS Arrow::arrow_static)
endif()

thirdparty_map_imported_config(Arrow::arrow_static)
message(DEBUG "Arrow imported into superproject: ${ARROW_INSTALL_DIR}")

find_package(ArrowAcero CONFIG QUIET REQUIRED)
if(TARGET ArrowAcero::arrow_acero_static AND NOT TARGET ArrowAcero::arrow_acero)
    add_library(ArrowAcero::arrow_acero ALIAS ArrowAcero::arrow_acero_static)
endif()
thirdparty_map_imported_config(ArrowAcero::arrow_acero_static)
message(DEBUG "ArrowAcero imported into superproject: ${ARROW_INSTALL_DIR}")

find_package(ArrowCompute CONFIG QUIET REQUIRED)
if(TARGET ArrowCompute::arrow_compute_static AND NOT TARGET ArrowCompute::arrow_compute)
    add_library(ArrowCompute::arrow_compute ALIAS ArrowCompute::arrow_compute_static)
endif()
thirdparty_map_imported_config(ArrowCompute::arrow_compute_static)
message(DEBUG "ArrowCompute imported into superproject: ${ARROW_INSTALL_DIR}")

find_package(ArrowDataset CONFIG QUIET REQUIRED)
if(TARGET ArrowDataset::arrow_dataset_static AND NOT TARGET ArrowDataset::arrow_dataset)
    add_library(ArrowDataset::arrow_dataset ALIAS ArrowDataset::arrow_dataset_static)
endif()
thirdparty_map_imported_config(ArrowDataset::arrow_dataset_static)
message(DEBUG "ArrowDataset imported into superproject: ${ARROW_INSTALL_DIR}")

find_package(ArrowFlight CONFIG QUIET REQUIRED)
if(TARGET ArrowFlight::arrow_flight_static AND NOT TARGET ArrowFlight::arrow_flight)
    add_library(ArrowFlight::arrow_flight ALIAS ArrowFlight::arrow_flight_static)
endif()
thirdparty_map_imported_config(ArrowFlight::arrow_flight_static)
message(DEBUG "ArrowFlight imported into superproject: ${ARROW_INSTALL_DIR}")

find_package(ArrowFlightSql CONFIG QUIET REQUIRED)
if(TARGET ArrowFlightSql::arrow_flight_sql_static AND NOT TARGET ArrowFlightSql::arrow_flight_sql)
    add_library(ArrowFlightSql::arrow_flight_sql ALIAS ArrowFlightSql::arrow_flight_sql_static)
endif()
thirdparty_map_imported_config(ArrowFlightSql::arrow_flight_sql_static)
message(DEBUG "ArrowFlightSql imported into superproject: ${ARROW_INSTALL_DIR}")

find_package(ArrowSubstrait CONFIG QUIET REQUIRED)
if(TARGET ArrowSubstrait::arrow_substrait_static AND NOT TARGET ArrowSubstrait::arrow_substrait)
    add_library(ArrowSubstrait::arrow_substrait ALIAS ArrowSubstrait::arrow_substrait_static)
endif()
thirdparty_map_imported_config(ArrowSubstrait::arrow_substrait_static)
message(DEBUG "ArrowSubstrait imported into superproject: ${ARROW_INSTALL_DIR}")

find_package(Gandiva CONFIG QUIET REQUIRED)
if(TARGET Gandiva::gandiva_static AND NOT TARGET Gandiva::gandiva)
    add_library(Gandiva::gandiva ALIAS Gandiva::gandiva_static)
endif()
thirdparty_map_imported_config(Gandiva::gandiva_static)
message(DEBUG "Gandiva imported into superproject: ${ARROW_INSTALL_DIR}")

find_package(Parquet CONFIG QUIET REQUIRED)
if(TARGET Parquet::parquet_static AND NOT TARGET Parquet::parquet)
    add_library(Parquet::parquet ALIAS Parquet::parquet_static)
endif()
thirdparty_map_imported_config(Parquet::parquet_static)
message(DEBUG "Parquet imported into superproject: ${ARROW_INSTALL_DIR}")

# --- Restore previous log level ---
if(_HALO_ARROW_PREV_LOG_LEVEL_SAVED)
    set(CMAKE_MESSAGE_LOG_LEVEL "${_HALO_ARROW_PREV_LOG_LEVEL}")
else()
    unset(CMAKE_MESSAGE_LOG_LEVEL)
endif()


# --------------------------------------------------------------------------------
# Targeted LLVM header filtering
# On Linux with Clang + libstdc++, Arrow/Gandiva's FindLLVMAlt exposes the system
# LLVM include root (e.g. /usr/lib/llvm-20/include) via LLVM::LLVM_HEADERS. That
# directory contains the libc++ and libc++abi headers (c++/v1/*, cxxabi.h) which
# must NOT participate in our translation unit searches, otherwise the wrong ABI
# layer may be selected (leading to duplicate __cxa* symbols or mixed allocation
# semantics). We cannot simply remove the entire root include path because LLVM
# headers (llvm/IR/..., clang/Basic/...) rely on it. Instead we create a filtered
# mirror that preserves required subdirectories while excluding the C++ standard
# library implementation directories.
#
# Strategy:
#   1. Detect an include directory matching the system LLVM pattern.
#   2. Materialize a filtered directory under the third-party build tree.
#   3. Copy top-level headers and all needed subdirectories EXCEPT those named:
#        c++        (contains libc++/v1)
#        libc++     (rare alternate layout)
#        libc++abi  (ABI impl headers)
#   4. Redirect LLVM::LLVM_HEADERS' INTERFACE_INCLUDE_DIRECTORIES to the filtered
#      path so dependent targets only see sanitized headers.
#
# This avoids global flag hacks (-nostdinc++) and keeps configuration minimal.
# Applied only on non-Apple UNIX platforms (Linux). macOS is unaffected because
# we intentionally allow the platform default libc++ there.
# --------------------------------------------------------------------------------
if(UNIX AND NOT APPLE AND TARGET LLVM::LLVM_HEADERS)
    get_target_property(_halo_llvm_header_includes LLVM::LLVM_HEADERS INTERFACE_INCLUDE_DIRECTORIES)
    if(_halo_llvm_header_includes)
        set(_halo_llvm_filtered_dir "${THIRDPARTY_BUILD_DIR}/arrow/llvm_headers_filtered")
        set(_halo_need_filter FALSE)
        foreach(_inc_dir IN LISTS _halo_llvm_header_includes)
            # Heuristic: system-discovered LLVM includes live under
            #   /usr/lib/llvm/include            (unversioned)
            #   /usr/lib/llvm-<ver>/include      (versioned)
            # Use a regex that matches both forms.
            if(_inc_dir MATCHES "/llvm(-[0-9]+)?/include$")
                set(_halo_need_filter TRUE)
                if(NOT EXISTS "${_halo_llvm_filtered_dir}")
                    file(MAKE_DIRECTORY "${_halo_llvm_filtered_dir}")
                    # Enumerate entries in the source include root
                    file(GLOB _halo_llvm_root_entries RELATIVE "${_inc_dir}" "${_inc_dir}/*")
                    foreach(_entry IN LISTS _halo_llvm_root_entries)
                        # Skip C++ standard library implementation directories and libc++abi top-level headers.
                        # The top-level cxxabi.h in the LLVM include root belongs to libc++abi and
                        # conflicts with libstdc++'s own internal ABI headers when we are compiling
                        # with libstdc++. Copying it would surface conflicting declarations for
                        # symbols like __cxa_init_primary_exception. Exclude it explicitly.
                        if(_entry STREQUAL "c++" OR _entry STREQUAL "libc++" OR _entry STREQUAL "libc++abi" OR _entry STREQUAL "cxxabi.h")
                            continue()
                        endif()
                        if(IS_DIRECTORY "${_inc_dir}/${_entry}")
                            file(COPY "${_inc_dir}/${_entry}" DESTINATION "${_halo_llvm_filtered_dir}/${_entry}")
                        else()
                            # Copy top-level header file
                            file(COPY "${_inc_dir}/${_entry}" DESTINATION "${_halo_llvm_filtered_dir}")
                        endif()
                    endforeach()
                endif()
            endif()
        endforeach()
        if(_halo_need_filter)
            # Replace include directories with only the filtered path to prevent
            # libc++/libc++abi headers from being reachable via this target.
            set_target_properties(LLVM::LLVM_HEADERS PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${_halo_llvm_filtered_dir}")
            message(DEBUG "[arrow] Applied targeted LLVM header filtering: ${_halo_llvm_filtered_dir}")
        endif()
    endif()
endif()

