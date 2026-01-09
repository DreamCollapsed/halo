#[[
  duckdb.cmake (submodule integration)
  - Ensures DuckDB submodule is initialized and at correct commit
  - Sets DuckDB CMake cache options
  - Caller should then: add_subdirectory(duckdb)

  Usage in top-level CMakeLists.txt:
    include(cmake/DuckDB.cmake)
    add_subdirectory(duckdb)
]]

# The commit hash to pin to (currently tip of main)
set(DUCKDB_COMMIT_HASH "48bdbbebe4403a086d6fb202a97b6658e136c65c")

include_guard(GLOBAL)

set(HALO_DUCKDB_SOURCE_DIR "${CMAKE_SOURCE_DIR}/duckdb" CACHE PATH "DuckDB source dir" FORCE)

find_package(Git REQUIRED QUIET)

# Check if DuckDB submodule is initialized
set(DUCKDB_NEEDS_INIT FALSE)
set(DUCKDB_NEEDS_PATCH FALSE)

if(NOT EXISTS "${HALO_DUCKDB_SOURCE_DIR}/CMakeLists.txt")
  set(DUCKDB_NEEDS_INIT TRUE)
  set(DUCKDB_NEEDS_PATCH TRUE)
  message(STATUS "DuckDB submodule not initialized. Will initialize and apply patches.")
else()
  # Check if patches have been applied by looking for a patch marker
  if(NOT EXISTS "${HALO_DUCKDB_SOURCE_DIR}/.duckdb_patched")
    set(DUCKDB_NEEDS_PATCH TRUE)
  endif()
endif()

# Initialize submodule if needed
if(DUCKDB_NEEDS_INIT)
  if(EXISTS "${CMAKE_SOURCE_DIR}/.git" AND GIT_EXECUTABLE)
    # Try to update first
    execute_process(
      COMMAND "${GIT_EXECUTABLE}" submodule update --init --recursive duckdb
      WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
      RESULT_VARIABLE _submodule_res
      OUTPUT_QUIET
      ERROR_QUIET
    )
    
    # If update failed (likely because it's not added yet or .gitmodules is out of sync), try to fix
    if(NOT _submodule_res EQUAL 0)
      message(STATUS "DuckDB submodule update failed, attempting to initialize...")
      execute_process(
        COMMAND "${GIT_EXECUTABLE}" submodule update --init --recursive --force duckdb
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
        RESULT_VARIABLE _init_res
      )
      
      if(NOT _init_res EQUAL 0)
        message(FATAL_ERROR "Failed to initialize DuckDB submodule")
      endif()
    endif()
  endif()
endif()

# Fetch remote updates to ensure all commits are available
if(EXISTS "${HALO_DUCKDB_SOURCE_DIR}/.git" AND GIT_EXECUTABLE)
  message(STATUS "Fetching DuckDB remote updates...")
  execute_process(
    COMMAND "${GIT_EXECUTABLE}" fetch origin "${DUCKDB_COMMIT_HASH}"
    WORKING_DIRECTORY "${HALO_DUCKDB_SOURCE_DIR}"
    RESULT_VARIABLE _fetch_res
    OUTPUT_QUIET
    ERROR_QUIET
  )
  if(NOT _fetch_res EQUAL 0)
    message(WARNING "Failed to fetch DuckDB remote updates, will attempt checkout anyway")
  endif()
endif()

# Ensure we are at the correct commit
if(EXISTS "${HALO_DUCKDB_SOURCE_DIR}/.git" AND GIT_EXECUTABLE)
  execute_process(
    COMMAND "${GIT_EXECUTABLE}" rev-parse HEAD
    WORKING_DIRECTORY "${HALO_DUCKDB_SOURCE_DIR}"
    OUTPUT_VARIABLE _current_duckdb_hash
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  
  if(NOT "${_current_duckdb_hash}" MATCHES "^${DUCKDB_COMMIT_HASH}")
    message(STATUS "Checking out DuckDB commit ${DUCKDB_COMMIT_HASH}...")
    execute_process(
      COMMAND "${GIT_EXECUTABLE}" checkout "${DUCKDB_COMMIT_HASH}"
      WORKING_DIRECTORY "${HALO_DUCKDB_SOURCE_DIR}"
      RESULT_VARIABLE _checkout_res
    )
    if(NOT _checkout_res EQUAL 0)
      message(FATAL_ERROR "Failed to checkout DuckDB commit ${DUCKDB_COMMIT_HASH}")
    endif()

    # Re-check hash
    execute_process(
        COMMAND "${GIT_EXECUTABLE}" rev-parse HEAD
        WORKING_DIRECTORY "${HALO_DUCKDB_SOURCE_DIR}"
        OUTPUT_VARIABLE _current_duckdb_hash
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(NOT "${_current_duckdb_hash}" MATCHES "^${DUCKDB_COMMIT_HASH}")
        message(FATAL_ERROR "DuckDB commit after checkout (${_current_duckdb_hash}) still differs from required ${DUCKDB_COMMIT_HASH}")
    endif()

    if(NOT DUCKDB_NEEDS_INIT AND EXISTS "${HALO_DUCKDB_SOURCE_DIR}/.duckdb_patched")
        set(DUCKDB_NEEDS_PATCH TRUE)
        message(STATUS "DuckDB commit changed; will re-apply patches.")
    endif()
  endif()
endif()

# Apply patches if needed
if(DUCKDB_NEEDS_PATCH)
  set(DUCKDB_PATCH_FILE "${CMAKE_SOURCE_DIR}/cmake/patches/duckdb.patch")
  if(EXISTS "${DUCKDB_PATCH_FILE}")
    if(EXISTS "${HALO_DUCKDB_SOURCE_DIR}/.duckdb_patched")
      file(REMOVE "${HALO_DUCKDB_SOURCE_DIR}/.duckdb_patched")
    endif()
    
    execute_process(
      COMMAND "${GIT_EXECUTABLE}" apply "${DUCKDB_PATCH_FILE}"
      WORKING_DIRECTORY "${HALO_DUCKDB_SOURCE_DIR}"
      RESULT_VARIABLE _patch_res
      OUTPUT_VARIABLE _patch_output
      ERROR_VARIABLE _patch_error)
    
    if(_patch_res EQUAL 0)
      file(WRITE "${HALO_DUCKDB_SOURCE_DIR}/.duckdb_patched" 
            "# This file indicates that DuckDB patches have been applied\n"
            "# Commit: ${_current_duckdb_hash}\n"
            "# Patch file: ${DUCKDB_PATCH_FILE}\n"
            "# Applied at: ${CMAKE_CURRENT_LIST_FILE}:${CMAKE_CURRENT_LIST_LINE}\n"
      )
      message(STATUS "Successfully applied DuckDB patches.")
    else()
      message(FATAL_ERROR "Failed to apply DuckDB patches (exit ${_patch_res}). Output: ${_patch_output}. Error: ${_patch_error}")
    endif()
  else()
    message(WARNING "No DuckDB patch file found at ${DUCKDB_PATCH_FILE}, skipping patch application.")
  endif()
endif()

# ----------------------------------------------------------------------------
# DuckDB CMake Configuration
# ----------------------------------------------------------------------------
set(BUILD_UNITTESTS OFF CACHE BOOL "Disable DuckDB unit tests" FORCE)
set(BUILD_SHELL OFF CACHE BOOL "Disable DuckDB shell" FORCE)
set(BUILD_BENCHMARKS OFF CACHE BOOL "Disable DuckDB benchmarks" FORCE)
set(BUILD_PYTHON OFF CACHE BOOL "Disable DuckDB Python API" FORCE)
set(BUILD_R OFF CACHE BOOL "Disable DuckDB R API" FORCE)

set(BUILD_EXTENSIONS "parquet;json;icu;jemalloc" CACHE STRING "DuckDB extensions to build" FORCE)

set(ENABLE_SANITIZER OFF CACHE BOOL "Enable address sanitizer" FORCE)
set(ENABLE_UBSAN OFF CACHE BOOL "Enable undefined behavior sanitizer" FORCE)
set(DISABLE_VPTR_SANITIZER ON CACHE BOOL "Disable vptr sanitizer" FORCE)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

function(_create_duckdb_unified_target_internal)
  if(TARGET duckdb_static)
    add_library(halo_duckdb_unified INTERFACE)
    target_link_libraries(halo_duckdb_unified INTERFACE
        duckdb_static
        $<TARGET_OBJECTS:duckdb_generated_extension_loader>
        parquet_extension
        json_extension
        icu_extension
        core_functions_extension
        jemalloc_extension
    )
    target_include_directories(halo_duckdb_unified INTERFACE 
        $<BUILD_INTERFACE:${HALO_DUCKDB_SOURCE_DIR}/src/include>
    )
    message(STATUS "Created halo_duckdb_unified target automatically")
  endif()
endfunction()

cmake_language(DEFER DIRECTORY ${CMAKE_SOURCE_DIR} CALL _create_duckdb_unified_target_internal)
