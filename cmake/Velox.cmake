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

if(TRUE)
  if(GIT_EXECUTABLE)
    # Verify .git directory exists to avoid running in an exported source tree
    if(EXISTS "${CMAKE_SOURCE_DIR}/.git")
      # Query gitlink
      execute_process(
        COMMAND "${GIT_EXECUTABLE}" ls-files --stage velox
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
        OUTPUT_VARIABLE _velox_ls_stage
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET)
      string(FIND "${_velox_ls_stage}" "160000" _gitlink_pos)
      if(_gitlink_pos EQUAL -1)
        # Gitlink missing: check whether .gitmodules still references velox
        set(_need_restore FALSE)
        if(EXISTS "${CMAKE_SOURCE_DIR}/.gitmodules")
          file(READ "${CMAKE_SOURCE_DIR}/.gitmodules" _gm)
          if(_gm MATCHES "\n\[submodule \"velox\"\]\n")
            set(_need_restore TRUE)
          endif()
        endif()
        if(_need_restore)
          message(WARNING "Velox gitlink missing from index; attempting automatic re-add of submodule.")
          # Attempt re-add (non-fatal fallback: user can manually restore if this fails)
          execute_process(
            COMMAND "${GIT_EXECUTABLE}" submodule add https://github.com/facebookincubator/velox.git velox
            WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
            RESULT_VARIABLE _add_res
            OUTPUT_QUIET ERROR_VARIABLE _add_err)
          if(_add_res EQUAL 0)
            message(STATUS "Velox submodule re-added. Initializing...")
            execute_process(
              COMMAND "${GIT_EXECUTABLE}" submodule update --init --recursive velox
              WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
              RESULT_VARIABLE _upd_res
              OUTPUT_QUIET ERROR_VARIABLE _upd_err)
            if(_upd_res EQUAL 0)
              # Checkout pinned commit if defined
              if(DEFINED VELOX_SHA256 AND NOT VELOX_SHA256 STREQUAL "")
                execute_process(
                  COMMAND "${GIT_EXECUTABLE}" -C velox checkout ${VELOX_SHA256}
                  WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
                  RESULT_VARIABLE _co_res
                  OUTPUT_QUIET ERROR_VARIABLE _co_err)
                if(NOT _co_res EQUAL 0)
                  message(WARNING "Failed to checkout pinned Velox commit ${VELOX_SHA256} after auto-restore: ${_co_err}")
                else()
                  message(STATUS "Velox auto-restore: pinned commit ${VELOX_SHA256} checked out.")
                endif()
              endif()
            else()
              message(WARNING "Velox auto-restore submodule update failed: ${_upd_err}")
            endif()
          else()
            message(WARNING "Velox auto-restore failed to add submodule: ${_add_err}")
          endif()
        else()
          message(WARNING "Velox directory missing and .gitmodules has no velox entry; cannot auto-restore.")
        endif()
      endif()
    endif()
  endif()
endif()

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
  
  execute_process(
    COMMAND "${GIT_EXECUTABLE}" submodule update --init --recursive velox
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    RESULT_VARIABLE _submodule_res
    OUTPUT_QUIET ERROR_QUIET)
  if(NOT _submodule_res EQUAL 0)
    message(FATAL_ERROR "Failed to initialize Velox submodule (exit ${_submodule_res}).")
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

# Threading
set(THREADS_PREFER_PTHREAD_FLAG ON)
set(CMAKE_USE_PTHREADS_INIT 1)
set(CMAKE_THREAD_LIBS_INIT "-lpthread")

# Openssl
set(OPENSSL_ROOT_DIR "${THIRDPARTY_INSTALL_DIR}/openssl")

list(PREPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake/modules")
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/thirdparty/src/fizz/build/fbcode_builder/CMake")

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

# Schedule the unified target creation to happen after all CMakeLists.txt files are processed
cmake_language(DEFER DIRECTORY ${CMAKE_SOURCE_DIR} CALL _create_velox_unified_target_internal)
