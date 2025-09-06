#[[
  velox.cmake (single-file integration)
  - Acquires Velox sources via Git (clone + optional checkout + submodules)
  - Sets Velox CMake cache options
  - Caller should then: add_subdirectory(velox)

  Usage in top-level CMakeLists.txt:
    include(cmake/Velox.cmake)
    add_subdirectory(velox)
]]
set(VELOX_URL "https://github.com/facebookincubator/velox")
set(VELOX_SHA256 "e23a4e90fb3cfcb159b26072b55b824c9c630b71")

include_guard(GLOBAL)

set(HALO_VELOX_SOURCE_DIR "${CMAKE_SOURCE_DIR}/velox" CACHE PATH "Velox source dir" FORCE)

if(NOT EXISTS "${HALO_VELOX_SOURCE_DIR}/CMakeLists.txt")
  find_package(Git QUIET)
  if(NOT GIT_EXECUTABLE)
    message(FATAL_ERROR "Git not found but required to acquire Velox sources.")
  endif()

  file(MAKE_DIRECTORY "${HALO_VELOX_SOURCE_DIR}")

  if(DEFINED VELOX_SHA256 AND NOT VELOX_SHA256 STREQUAL "")
    message(STATUS "Fetching Velox commit ${VELOX_SHA256} (shallow) into ${HALO_VELOX_SOURCE_DIR}")
    # Initialize empty repo and fetch only the desired commit shallowly
    execute_process(
      COMMAND "${GIT_EXECUTABLE}" init
      WORKING_DIRECTORY "${HALO_VELOX_SOURCE_DIR}"
      RESULT_VARIABLE _init_res
      OUTPUT_QUIET ERROR_QUIET)
    if(NOT _init_res EQUAL 0)
      message(FATAL_ERROR "Failed to initialize git repository at ${HALO_VELOX_SOURCE_DIR} (exit ${_init_res}).")
    endif()
    execute_process(
      COMMAND "${GIT_EXECUTABLE}" -C "${HALO_VELOX_SOURCE_DIR}" remote add origin "${VELOX_URL}"
      RESULT_VARIABLE _remote_res
      OUTPUT_QUIET ERROR_QUIET)
    if(NOT _remote_res EQUAL 0)
      message(FATAL_ERROR "Failed to add origin ${VELOX_URL} to ${HALO_VELOX_SOURCE_DIR} (exit ${_remote_res}).")
    endif()
    execute_process(
      COMMAND "${GIT_EXECUTABLE}" -C "${HALO_VELOX_SOURCE_DIR}" fetch --depth 1 origin "${VELOX_SHA256}"
      RESULT_VARIABLE _fetch_res
      OUTPUT_QUIET ERROR_QUIET)
    if(NOT _fetch_res EQUAL 0)
      message(FATAL_ERROR "Failed to fetch commit ${VELOX_SHA256} from ${VELOX_URL} (exit ${_fetch_res}).")
    endif()
    execute_process(
      COMMAND "${GIT_EXECUTABLE}" -C "${HALO_VELOX_SOURCE_DIR}" checkout --detach FETCH_HEAD
      RESULT_VARIABLE _checkout_res
      OUTPUT_QUIET ERROR_QUIET)
    if(NOT _checkout_res EQUAL 0)
      message(FATAL_ERROR "Failed to checkout commit ${VELOX_SHA256} in ${HALO_VELOX_SOURCE_DIR}.")
    endif()
  else()
    message(STATUS "Cloning Velox (shallow) from ${VELOX_URL} into ${HALO_VELOX_SOURCE_DIR}")
    execute_process(
      COMMAND "${GIT_EXECUTABLE}" clone --depth 1 "${VELOX_URL}" "${HALO_VELOX_SOURCE_DIR}"
      RESULT_VARIABLE _clone_res
      OUTPUT_QUIET ERROR_QUIET)
    if(NOT _clone_res EQUAL 0)
      message(FATAL_ERROR "Failed to clone Velox repository (exit ${_clone_res}) from ${VELOX_URL}.")
    endif()
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
  include_directories(BEFORE "${THIRDPARTY_INSTALL_DIR}/jemalloc/include")
  # Force include jemalloc headers using a different approach
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -include ${THIRDPARTY_INSTALL_DIR}/jemalloc/include/jemalloc/jemalloc.h")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -include ${THIRDPARTY_INSTALL_DIR}/jemalloc/include/jemalloc_prefix_compat.h")
endif()
