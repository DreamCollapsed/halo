#[[
  velox.cmake (submodule integration)
  - Ensures Velox submodule is initialized and at correct commit
  - Sets Velox CMake cache options
  - Caller should then: add_subdirectory(velox)

  Usage in top-level CMakeLists.txt:
    include(cmake/Velox.cmake)
    add_subdirectory(velox)
]]
set(VELOX_SHA256 "7274da53db330bb8ad691d394818248809c10ca8")

include_guard(GLOBAL)

set(HALO_VELOX_SOURCE_DIR "${CMAKE_SOURCE_DIR}/velox" CACHE PATH "Velox source dir" FORCE)

find_package(Git REQUIRED QUIET)

# Check if Velox submodule is initialized and has content
set(VELOX_NEEDS_INIT FALSE)
set(VELOX_NEEDS_PATCH FALSE)

if(NOT EXISTS "${HALO_VELOX_SOURCE_DIR}/CMakeLists.txt")
  set(VELOX_NEEDS_INIT TRUE)
  set(VELOX_NEEDS_PATCH TRUE)
  message(STATUS "Velox submodule not initialized. Will initialize and apply patches.")
else()
  # Check if patches have been applied by looking for a patch marker
  if(NOT EXISTS "${HALO_VELOX_SOURCE_DIR}/.velox_patched")
    set(VELOX_NEEDS_PATCH TRUE)
  endif()
endif()

# Initialize submodule if needed
if(VELOX_NEEDS_INIT)
  # Clean stale Velox build artifacts if build directory exists
  if(EXISTS "${CMAKE_BINARY_DIR}/velox")
    message(STATUS "Removing stale Velox build artifacts from ${CMAKE_BINARY_DIR}/velox")
    file(REMOVE_RECURSE "${CMAKE_BINARY_DIR}/velox")
  endif()
  
  if(EXISTS "${CMAKE_SOURCE_DIR}/.git" AND GIT_EXECUTABLE)
    execute_process(
      COMMAND "${GIT_EXECUTABLE}" submodule update --init --recursive velox
      WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
      RESULT_VARIABLE _submodule_res
      OUTPUT_VARIABLE _submodule_out
      ERROR_VARIABLE _submodule_err
      OUTPUT_STRIP_TRAILING_WHITESPACE
      ERROR_STRIP_TRAILING_WHITESPACE)
    if(NOT _submodule_res EQUAL 0)
      set(_velox_dir_exists FALSE)
      if(EXISTS "${HALO_VELOX_SOURCE_DIR}/.git" OR EXISTS "${HALO_VELOX_SOURCE_DIR}/CMakeLists.txt")
        set(_velox_dir_exists TRUE)
      endif()
      
      if(_velox_dir_exists)
        message(WARNING "Velox submodule update failed (exit=${_submodule_res}), but local velox directory detected. Reusing existing directory, skipping submodule add. Err='${_submodule_err}'")
      else()
        # No local directory: could be fresh build after deleting velox + pushing (index cleared)
        # First check and clean stale .git/modules/velox if exists
        set(_modules_velox_dir "${CMAKE_SOURCE_DIR}/.git/modules/velox")
        if(EXISTS "${_modules_velox_dir}")
          message(STATUS "Detected stale .git/modules/velox from previous build. Removing before submodule operations.")
          file(REMOVE_RECURSE "${_modules_velox_dir}")
        endif()
        
        message(DEBUG "Velox submodule initial update failed (exit=${_submodule_res}). Out='${_submodule_out}' Err='${_submodule_err}'. Attempting submodule add.")
        execute_process(
          COMMAND "${GIT_EXECUTABLE}" submodule add https://github.com/facebookincubator/velox.git velox
          WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
          RESULT_VARIABLE _add_res
          OUTPUT_VARIABLE _add_out
          ERROR_VARIABLE _add_err
          OUTPUT_STRIP_TRAILING_WHITESPACE
          ERROR_STRIP_TRAILING_WHITESPACE)
        if(_add_res EQUAL 0)
          message(DEBUG "Velox submodule added; retrying update.")
          execute_process(
            COMMAND "${GIT_EXECUTABLE}" submodule update --init --recursive velox
            WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
            RESULT_VARIABLE _upd2_res
            OUTPUT_VARIABLE _upd2_out
            ERROR_VARIABLE _upd2_err
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_STRIP_TRAILING_WHITESPACE)
          if(NOT _upd2_res EQUAL 0)
            if(EXISTS "${HALO_VELOX_SOURCE_DIR}/.git" OR EXISTS "${HALO_VELOX_SOURCE_DIR}/CMakeLists.txt")
              message(WARNING "Velox submodule update-after-add failed (exit=${_upd2_res}). Err='${_upd2_err}'. Local velox directory detected, continuing (treated as manual clone).")
            else()
              message(FATAL_ERROR "Velox submodule update after add failed: ${_upd2_err}")
            endif()
          endif()
        else()
          # Check if failure is due to leftover .git/modules/velox
          string(TOLOWER "${_add_err}" _add_err_lower)
          if(_add_err_lower MATCHES "a git directory for 'velox' is found locally")
            # Clean up stale git modules directory and retry
            set(_modules_velox_dir "${CMAKE_SOURCE_DIR}/.git/modules/velox")
            if(EXISTS "${_modules_velox_dir}")
              message(STATUS "Detected stale .git/modules/velox. Removing and retrying submodule add.")
              file(REMOVE_RECURSE "${_modules_velox_dir}")
              execute_process(
                COMMAND "${GIT_EXECUTABLE}" submodule add https://github.com/facebookincubator/velox.git velox
                WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
                RESULT_VARIABLE _add_retry_res
                OUTPUT_VARIABLE _add_retry_out
                ERROR_VARIABLE _add_retry_err
                OUTPUT_STRIP_TRAILING_WHITESPACE
                ERROR_STRIP_TRAILING_WHITESPACE)
              if(_add_retry_res EQUAL 0)
                message(STATUS "Velox submodule added after cleanup; running update.")
                execute_process(
                  COMMAND "${GIT_EXECUTABLE}" submodule update --init --recursive velox
                  WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
                  RESULT_VARIABLE _upd3_res
                  OUTPUT_QUIET ERROR_QUIET)
                if(NOT _upd3_res EQUAL 0)
                  message(WARNING "Velox submodule update after cleanup failed, but continuing.")
                endif()
              else()
                message(FATAL_ERROR "Velox submodule add retry failed (exit=${_add_retry_res}). Err='${_add_retry_err}'. Please run manually: rm -rf .git/modules/velox && git submodule add https://github.com/facebookincubator/velox.git velox")
              endif()
            else()
              message(FATAL_ERROR "Velox submodule add failed (exit=${_add_res}). Err='${_add_err}'. No stale modules found. Please investigate manually.")
            endif()
          elseif(EXISTS "${HALO_VELOX_SOURCE_DIR}/.git" OR EXISTS "${HALO_VELOX_SOURCE_DIR}/CMakeLists.txt")
            message(WARNING "Velox submodule add failed (exit=${_add_res}). Err='${_add_err}'. Existing velox directory detected, continuing (skipping fatal).")
          else()
            message(FATAL_ERROR "Velox submodule add failed (exit=${_add_res}). Out='${_add_out}' Err='${_add_err}'. Please run manually: git clone https://github.com/facebookincubator/velox.git velox")
          endif()
        endif()
      endif()
    endif()
  else()
    if(EXISTS "${HALO_VELOX_SOURCE_DIR}/CMakeLists.txt")
      message(WARNING ".git directory not found or Git unavailable, but local velox directory exists. Skipping submodule initialization.")
    else()
      message(FATAL_ERROR "Git or .git directory unavailable and velox source missing. Cannot initialize Velox. Please clone manually if needed.")
    endif()
  endif()
endif()

# Ensure we're at the correct commit
if(DEFINED VELOX_SHA256 AND NOT VELOX_SHA256 STREQUAL "")
  if(GIT_EXECUTABLE)
    # Fetch latest refs (non-fatal if offline)
    execute_process(
      COMMAND "${GIT_EXECUTABLE}" fetch --depth 1 origin main
      WORKING_DIRECTORY "${HALO_VELOX_SOURCE_DIR}"
      RESULT_VARIABLE _fetch_res
      OUTPUT_QUIET ERROR_QUIET)
    execute_process(
      COMMAND "${GIT_EXECUTABLE}" rev-parse HEAD
      WORKING_DIRECTORY "${HALO_VELOX_SOURCE_DIR}"
      OUTPUT_VARIABLE _current_commit
      OUTPUT_STRIP_TRAILING_WHITESPACE
      ERROR_QUIET)
    if(NOT _current_commit STREQUAL VELOX_SHA256)
      message(STATUS "Velox commit mismatch (have=${_current_commit} want=${VELOX_SHA256}); attempting checkout.")
      execute_process(
        COMMAND "${GIT_EXECUTABLE}" checkout ${VELOX_SHA256}
        WORKING_DIRECTORY "${HALO_VELOX_SOURCE_DIR}"
        RESULT_VARIABLE _checkout_res
        OUTPUT_VARIABLE _checkout_out
        ERROR_VARIABLE _checkout_err)
      if(NOT _checkout_res EQUAL 0)
        message(FATAL_ERROR "Failed to checkout required Velox commit ${VELOX_SHA256}. Output='${_checkout_out}' Error='${_checkout_err}'")
      endif()
      # Re-parse HEAD
      execute_process(
        COMMAND "${GIT_EXECUTABLE}" rev-parse HEAD
        WORKING_DIRECTORY "${HALO_VELOX_SOURCE_DIR}"
        OUTPUT_VARIABLE _current_commit
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET)
      if(NOT _current_commit STREQUAL VELOX_SHA256)
        message(FATAL_ERROR "Velox commit after checkout (${_current_commit}) still differs from required ${VELOX_SHA256}")
      endif()
      if(NOT VELOX_NEEDS_INIT AND EXISTS "${HALO_VELOX_SOURCE_DIR}/.velox_patched")
        set(VELOX_NEEDS_PATCH TRUE)
        message(STATUS "Velox commit changed; will re-apply patches.")
      endif()
    endif()
  endif()
endif()

# Apply patches if needed
if(VELOX_NEEDS_PATCH)
  set(VELOX_PATCH_FILE "${CMAKE_SOURCE_DIR}/cmake/patches/velox.patch")
  if(EXISTS "${VELOX_PATCH_FILE}")
    if(EXISTS "${HALO_VELOX_SOURCE_DIR}/.velox_patched")
      file(REMOVE "${HALO_VELOX_SOURCE_DIR}/.velox_patched")
    endif()
    
    execute_process(
      COMMAND "${GIT_EXECUTABLE}" apply "${VELOX_PATCH_FILE}"
      WORKING_DIRECTORY "${HALO_VELOX_SOURCE_DIR}"
      RESULT_VARIABLE _patch_res
      OUTPUT_VARIABLE _patch_output
      ERROR_VARIABLE _patch_error)
    
    if(_patch_res EQUAL 0)
      file(WRITE "${HALO_VELOX_SOURCE_DIR}/.velox_patched" 
            "# This file indicates that Velox patches have been applied
"
            "# Commit: ${_current_commit}
"
            "# Patch file: ${VELOX_PATCH_FILE}
"
            "# Applied at: ${CMAKE_CURRENT_LIST_FILE}:${CMAKE_CURRENT_LIST_LINE}
"
      )
      message(STATUS "Successfully applied Velox patches.")
    else()
      message(FATAL_ERROR "Failed to apply Velox patches (exit ${_patch_res}). Output: ${_patch_output}. Error: ${_patch_error}")
    endif()
  else()
    message(WARNING "No Velox patch file found at ${VELOX_PATCH_FILE}, skipping patch application.")
  endif()
endif()


# 3) Set Velox build options and dependency hints
set(VELOX_BUILD_SHARED            OFF      CACHE BOOL   "" FORCE)
set(VELOX_BUILD_STATIC            ON       CACHE BOOL   "" FORCE)
set(VELOX_MONO_LIBRARY            ON       CACHE BOOL   "" FORCE)
set(VELOX_BUILD_TESTING           OFF      CACHE BOOL   "" FORCE)
set(VELOX_BUILD_TEST_UTILS        OFF      CACHE BOOL   "" FORCE)
set(VELOX_BUILD_VECTOR_TEST_UTILS OFF      CACHE BOOL   "" FORCE)
set(VELOX_ENABLE_EXAMPLES         OFF      CACHE BOOL   "" FORCE)
set(VELOX_ENABLE_BENCHMARKS       OFF      CACHE BOOL   "" FORCE)
set(VELOX_ENABLE_BENCHMARKS_BASIC OFF      CACHE BOOL   "" FORCE)
set(VELOX_ENABLE_REMOTE_FUNCTIONS OFF      CACHE BOOL   "" FORCE)
set(VELOX_ENABLE_JSON             ON       CACHE BOOL   "" FORCE)
set(VELOX_ENABLE_CSV              ON       CACHE BOOL   "" FORCE)
set(VELOX_ENABLE_S3               OFF      CACHE BOOL   "" FORCE)
set(VELOX_ENABLE_GCS              OFF      CACHE BOOL   "" FORCE)
set(VELOX_ENABLE_ABFS             OFF      CACHE BOOL   "" FORCE)
set(VELOX_ENABLE_HDFS             OFF      CACHE BOOL   "" FORCE)
set(VELOX_ENABLE_PRESTO_FUNCTIONS ON       CACHE BOOL   "" FORCE)
set(VELOX_ENABLE_SPARK_FUNCTIONS  ON       CACHE BOOL   "" FORCE)
set(VELOX_ENABLE_ARROW            ON       CACHE BOOL   "" FORCE)
set(VELOX_ENABLE_PARQUET          ON       CACHE BOOL   "" FORCE)
set(VELOX_ENABLE_ZSTD             ON       CACHE BOOL   "" FORCE)
set(VELOX_ENABLE_LZ4              ON       CACHE BOOL   "" FORCE)
set(VELOX_ENABLE_SNAPPY           ON       CACHE BOOL   "" FORCE)
set(VELOX_ENABLE_FAISS            ON       CACHE BOOL   "" FORCE)
set(VELOX_ENABLE_ICU              ON       CACHE BOOL   "" FORCE)
set(VELOX_ENABLE_GEO              ON       CACHE BOOL   "" FORCE)
set(VELOX_ENABLE_OPENSSL          ON       CACHE BOOL   "" FORCE)
set(VELOX_ENABLE_OPENMP           ON       CACHE BOOL   "" FORCE)
set(VELOX_ENABLE_ZLIB             ON       CACHE BOOL   "" FORCE)
set(VELOX_ZLIB_TYPE               static   CACHE STRING "" FORCE)
set(VELOX_GFLAGS_TYPE             static   CACHE STRING "" FORCE)

# Velox SIMD compatibility: limit to AVX2 (x86-64-v3) to avoid AVX-512 incompatibility
# Velox's SimdUtil.h does not implement AVX-512 versions of certain operations (e.g., CRC32)
# Override x86-64-v4 flags set by main CMakeLists.txt for Velox subdirectory only
if(CMAKE_CXX_FLAGS MATCHES "-march=x86-64-v4")
    string(REGEX REPLACE "-march=x86-64-v4" "-march=x86-64-v3" VELOX_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
    set(CMAKE_CXX_FLAGS "${VELOX_CXX_FLAGS}" CACHE STRING "Velox CXX flags (AVX2 max)" FORCE)
    message(STATUS "[velox] Overriding -march=x86-64-v4 to -march=x86-64-v3 (AVX2) for Velox compatibility")
endif()
if(CMAKE_C_FLAGS MATCHES "-march=x86-64-v4")
    string(REGEX REPLACE "-march=x86-64-v4" "-march=x86-64-v3" VELOX_C_FLAGS "${CMAKE_C_FLAGS}")
    set(CMAKE_C_FLAGS "${VELOX_C_FLAGS}" CACHE STRING "Velox C flags (AVX2 max)" FORCE)
endif()

set(VELOX_DEPENDENCY_SOURCE       SYSTEM   CACHE STRING "" FORCE)
set(Arrow_SOURCE                  SYSTEM   CACHE STRING "" FORCE)
set(zstd_SOURCE                   SYSTEM   CACHE STRING "" FORCE)
set(LZ4_SOURCE                    SYSTEM   CACHE STRING "" FORCE)
set(Snappy_SOURCE                 SYSTEM   CACHE STRING "" FORCE)
set(faiss_SOURCE                  SYSTEM   CACHE STRING "" FORCE)
set(ICU_SOURCE                    SYSTEM   CACHE STRING "" FORCE)
set(GEOS_SOURCE                   SYSTEM   CACHE STRING "" FORCE)
set(OpenSSL_SOURCE                SYSTEM   CACHE STRING "" FORCE)
set(Boost_SOURCE                  SYSTEM   CACHE STRING "" FORCE)
set(gflags_SOURCE                 SYSTEM   CACHE STRING "" FORCE)
set(ZLIB_SOURCE                   SYSTEM   CACHE STRING "" FORCE)
set(fmt_SOURCE                    SYSTEM   CACHE STRING "" FORCE)
set(glog_SOURCE                   SYSTEM   CACHE STRING "" FORCE)
set(folly_SOURCE                  SYSTEM   CACHE STRING "" FORCE)
set(Protobuf_SOURCE               SYSTEM   CACHE STRING "" FORCE)
set(re2_SOURCE                    SYSTEM   CACHE STRING "" FORCE)
set(simdjson_SOURCE               SYSTEM   CACHE STRING "" FORCE)
set(double-conversion_SOURCE      SYSTEM   CACHE STRING "" FORCE)
set(xsimd_SOURCE                  SYSTEM   CACHE STRING "" FORCE)
set(stemmer_SOURCE                SYSTEM   CACHE STRING "" FORCE)

# Sodium
set(sodium_USE_STATIC_LIBS ON)
set(sodium_PKG_STATIC_FOUND TRUE)
set(sodium_PKG_STATIC_LIBRARIES libsodium.a)
set(sodium_PKG_STATIC_LIBRARY_DIRS ${THIRDPARTY_INSTALL_DIR}/libsodium/lib)
set(sodium_PKG_STATIC_INCLUDE_DIRS ${THIRDPARTY_INSTALL_DIR}/libsodium/include)

# Zlib
set(ZLIB_FOUND TRUE)
set(ZLIB_INCLUDE_DIRS ${THIRDPARTY_INSTALL_DIR}/zlib/include)
set(ZLIB_LIBRARIES ${THIRDPARTY_INSTALL_DIR}/zlib/lib/libz.a)
set(ZLIB_VERSION_STRING "1.3.1")

# Zstd - Force configuration to prevent Velox from finding system zstd
set(ZSTD_FOUND TRUE CACHE BOOL "zstd found" FORCE)
set(ZSTD_ROOT_DIR "${THIRDPARTY_INSTALL_DIR}/zstd" CACHE PATH "zstd root directory" FORCE)
set(ZSTD_INCLUDE_DIR "${THIRDPARTY_INSTALL_DIR}/zstd/include" CACHE PATH "zstd include directory" FORCE)
set(ZSTD_LIBRARY "${THIRDPARTY_INSTALL_DIR}/zstd/lib/libzstd.a" CACHE FILEPATH "zstd library" FORCE)
set(zstd_DIR "${THIRDPARTY_INSTALL_DIR}/zstd/lib/cmake/zstd" CACHE PATH "zstd CMake config directory" FORCE)

# Threading
set(THREADS_PREFER_PTHREAD_FLAG ON)
set(CMAKE_USE_PTHREADS_INIT 1)
set(CMAKE_THREAD_LIBS_INIT "-lpthread")

# Openssl
set(OPENSSL_ROOT_DIR "${THIRDPARTY_INSTALL_DIR}/openssl")

list(PREPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake/modules")
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/thirdparty/src/fizz/build/fbcode_builder/CMake")

# Prepend thirdparty install directories to CMAKE_PREFIX_PATH
# This ensures that Velox's find_package() calls use our built libraries instead of system libraries
list(PREPEND CMAKE_PREFIX_PATH 
    "${THIRDPARTY_INSTALL_DIR}/zstd"
    "${THIRDPARTY_INSTALL_DIR}/lz4"
    "${THIRDPARTY_INSTALL_DIR}/snappy"
    "${THIRDPARTY_INSTALL_DIR}/gflags"
    "${THIRDPARTY_INSTALL_DIR}/glog"
    "${THIRDPARTY_INSTALL_DIR}/fmt"
    "${THIRDPARTY_INSTALL_DIR}/re2"
    "${THIRDPARTY_INSTALL_DIR}/folly"
    "${THIRDPARTY_INSTALL_DIR}/fizz"
    "${THIRDPARTY_INSTALL_DIR}/wangle"
    "${THIRDPARTY_INSTALL_DIR}/mvfst"
    "${THIRDPARTY_INSTALL_DIR}/simdjson"
    "${THIRDPARTY_INSTALL_DIR}/protobuf"
    "${THIRDPARTY_INSTALL_DIR}/geos"
    "${THIRDPARTY_INSTALL_DIR}/arrow"
)

find_package(gflags CONFIG REQUIRED)
if(TARGET gflags::gflags)
    if(NOT TARGET gflags)
        add_library(gflags ALIAS gflags::gflags)
    endif()
    
    if(NOT TARGET gflags_static)
        add_library(gflags_static ALIAS gflags::gflags)
    endif()
    
    if(NOT TARGET gflags_nothreads_static)
        add_library(gflags_nothreads_static ALIAS gflags::gflags)
    endif()
    
    set(gflags_FOUND TRUE)
    set(GFLAGS_FOUND TRUE)
    set(gflags_LIBRARIES gflags::gflags)
    set(GFLAGS_LIBRARIES gflags::gflags)
endif()

find_package(glog CONFIG REQUIRED)
if(TARGET glog::glog)
    get_target_property(_glog_interface_libs glog::glog INTERFACE_LINK_LIBRARIES)
    if(_glog_interface_libs)
        # Replace any bare "gflags" references with proper target
        list(TRANSFORM _glog_interface_libs REPLACE "^gflags$" "gflags::gflags")
        set_target_properties(glog::glog PROPERTIES INTERFACE_LINK_LIBRARIES "${_glog_interface_libs}")
    endif()
endif()

find_package(fmt       CONFIG REQUIRED)
find_package(re2       CONFIG REQUIRED)
find_package(Folly     CONFIG REQUIRED)
find_package(fizz      CONFIG REQUIRED)
find_package(wangle    CONFIG REQUIRED)
find_package(mvfst     CONFIG REQUIRED)
find_package(simdjson  CONFIG REQUIRED)
find_package(protobuf  CONFIG REQUIRED)
find_package(zstd      CONFIG REQUIRED)
find_package(Snappy    CONFIG REQUIRED)
find_package(GEOS      CONFIG REQUIRED)
find_package(Arrow     CONFIG REQUIRED)
find_package(lz4       CONFIG REQUIRED)
find_package(OpenMP    REQUIRED)

if(DEFINED THIRDPARTY_INSTALL_DIR AND EXISTS "${THIRDPARTY_INSTALL_DIR}/jemalloc/include/jemalloc/jemalloc.h")
  add_compile_definitions(FOLLY_HAVE_LIBJEMALLOC=1)
  # On macOS we force-include the prefix compat header to map non-je_ symbols.
  # On Linux this can trigger posix_memalign exception spec conflicts, so skip include directory entirely.
  if(APPLE)
    include_directories(BEFORE "${THIRDPARTY_INSTALL_DIR}/jemalloc/include")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -include ${THIRDPARTY_INSTALL_DIR}/jemalloc/include/jemalloc/jemalloc.h")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -include ${THIRDPARTY_INSTALL_DIR}/jemalloc/include/jemalloc_prefix_compat.h")
  endif()
endif()

# Create a unified Velox target for easier consumption in main project
# This function will be automatically called via cmake_language(DEFER) after velox is added
function(_create_velox_unified_target_internal)
  if(TARGET velox)
    add_library(halo_velox_unified INTERFACE)
    target_link_libraries(halo_velox_unified INTERFACE velox)
    target_include_directories(halo_velox_unified INTERFACE 
      $<BUILD_INTERFACE:${HALO_VELOX_SOURCE_DIR}>
      $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/velox>
    )

    target_include_directories(halo_velox_unified SYSTEM INTERFACE 
      ${HALO_VELOX_SOURCE_DIR}
      ${CMAKE_BINARY_DIR}/velox
    )
    message(STATUS "Created halo_velox_unified target automatically")
  endif()
endfunction()

# CRITICAL: Re-apply imported config mapping after Velox subdirectory is processed
# Velox's CMakeLists.txt calls find_package(zstd) and other packages, which resets target properties.
# We must re-apply the mapping after all find_package calls are complete.
function(_reapply_thirdparty_imported_config_mapping)
  include(${CMAKE_SOURCE_DIR}/thirdparty/ThirdpartyUtils.cmake)
  
  # Re-map all CONFIG-mode third-party targets that Velox uses
  if(TARGET zstd::libzstd_static)
      thirdparty_map_imported_config(zstd::libzstd_static)
      message(DEBUG "[Velox] Re-applied imported config mapping for zstd::libzstd_static")
  endif()
  if(TARGET LZ4::lz4_static)
      thirdparty_map_imported_config(LZ4::lz4_static)
      message(DEBUG "[Velox] Re-applied imported config mapping for LZ4::lz4_static")
  endif()
  if(TARGET LZ4::lz4)
      thirdparty_map_imported_config(LZ4::lz4)
      message(DEBUG "[Velox] Re-applied imported config mapping for LZ4::lz4")
  endif()
  if(TARGET Snappy::snappy)
      thirdparty_map_imported_config(Snappy::snappy)
      message(DEBUG "[Velox] Re-applied imported config mapping for Snappy::snappy")
  endif()
  if(TARGET Arrow::arrow_shared)
      thirdparty_map_imported_config(Arrow::arrow_shared)
      message(DEBUG "[Velox] Re-applied imported config mapping for Arrow::arrow_shared")
  endif()
  if(TARGET Arrow::arrow_static)
      thirdparty_map_imported_config(Arrow::arrow_static)
      message(DEBUG "[Velox] Re-applied imported config mapping for Arrow::arrow_static")
  endif()
  if(TARGET Parquet::parquet_shared)
      thirdparty_map_imported_config(Parquet::parquet_shared)
      message(DEBUG "[Velox] Re-applied imported config mapping for Parquet::parquet_shared")
  endif()
  if(TARGET Parquet::parquet_static)
      thirdparty_map_imported_config(Parquet::parquet_static)
      message(DEBUG "[Velox] Re-applied imported config mapping for Parquet::parquet_static")
  endif()
  if(TARGET protobuf::libprotobuf)
      thirdparty_map_imported_config(protobuf::libprotobuf)
      message(DEBUG "[Velox] Re-applied imported config mapping for protobuf::libprotobuf")
  endif()
  if(TARGET protobuf::libprotobuf-lite)
      thirdparty_map_imported_config(protobuf::libprotobuf-lite)
      message(DEBUG "[Velox] Re-applied imported config mapping for protobuf::libprotobuf-lite")
  endif()
  if(TARGET protobuf::libprotoc)
      thirdparty_map_imported_config(protobuf::libprotoc)
      message(DEBUG "[Velox] Re-applied imported config mapping for protobuf::libprotoc")
  endif()
  if(TARGET gRPC::grpc)
      thirdparty_map_imported_config(gRPC::grpc)
      message(DEBUG "[Velox] Re-applied imported config mapping for gRPC::grpc")
  endif()
  if(TARGET gRPC::grpc++)
      thirdparty_map_imported_config(gRPC::grpc++)
      message(DEBUG "[Velox] Re-applied imported config mapping for gRPC::grpc++")
  endif()
  if(TARGET re2::re2)
      thirdparty_map_imported_config(re2::re2)
      message(DEBUG "[Velox] Re-applied imported config mapping for re2::re2")
  endif()
  if(TARGET simdjson::simdjson)
      thirdparty_map_imported_config(simdjson::simdjson)
      message(DEBUG "[Velox] Re-applied imported config mapping for simdjson::simdjson")
  endif()
  if(TARGET fmt::fmt)
      thirdparty_map_imported_config(fmt::fmt)
      message(DEBUG "[Velox] Re-applied imported config mapping for fmt::fmt")
  endif()
  if(TARGET folly)
      thirdparty_map_imported_config(folly)
      message(DEBUG "[Velox] Re-applied imported config mapping for folly")
  endif()
  if(TARGET Folly::folly)
      thirdparty_map_imported_config(Folly::folly)
      message(DEBUG "[Velox] Re-applied imported config mapping for Folly::folly")
  endif()
  if(TARGET GEOS::geos)
      thirdparty_map_imported_config(GEOS::geos)
      message(DEBUG "[Velox] Re-applied imported config mapping for GEOS::geos")
  endif()
  if(TARGET GEOS::geos_c)
      thirdparty_map_imported_config(GEOS::geos_c)
      message(DEBUG "[Velox] Re-applied imported config mapping for GEOS::geos_c")
  endif()
endfunction()

cmake_language(DEFER DIRECTORY ${CMAKE_SOURCE_DIR} CALL _reapply_thirdparty_imported_config_mapping)
cmake_language(DEFER DIRECTORY ${CMAKE_SOURCE_DIR} CALL _create_velox_unified_target_internal)
