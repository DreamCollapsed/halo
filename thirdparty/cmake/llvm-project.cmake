# LLVM Project third-party integration
# Build OpenMP and libunwind runtimes using CMAKE_CACHE_ARGS to handle semicolons

thirdparty_setup_directories("llvm-project")

thirdparty_combine_flags(_llvm_cxx_flags FRAGMENTS "${HALO_CMAKE_CXX_FLAGS_BASE}")

thirdparty_build_cmake_library(llvm-project
    SOURCE_SUBDIR "runtimes"
    CMAKE_CACHE_ARGS
        "LLVM_ENABLE_RUNTIMES=openmp;libunwind"
        "CLANG_VERSION_MAJOR=21"
        "PACKAGE_VERSION=21.1.6"
        "CLANG_RESOURCE_DIR=21"
        "CMAKE_CXX_FLAGS=${_llvm_cxx_flags}"
        "OPENMP_FILECHECK_EXECUTABLE=/usr/bin/true"
        "OPENMP_LLVM_LIT_EXECUTABLE=/usr/bin/true"
        "OPENMP_NOT_EXECUTABLE=/usr/bin/true"
        "OPENMP_ENABLE_TESTING=OFF"
        "OPENMP_STANDALONE_BUILD=ON"
    CMAKE_ARGS
        -DLLVM_INCLUDE_TESTS=OFF
        -DLLVM_ENABLE_PROJECTS=""
        -DLLVM_INCLUDE_UTILS=ON
        -DLLVM_BUILD_UTILS=ON
        -DLLVM_INCLUDE_TOOLS=ON
        -DLLVM_BUILD_TOOLS=ON
        -DLLVM_INCLUDE_EXAMPLES=OFF
        -DLLVM_BUILD_EXAMPLES=OFF
        -DLLVM_INCLUDE_BENCHMARKS=OFF
        -DLLVM_BUILD_BENCHMARKS=OFF
        -DOPENMP_ENABLE_LIBOMPTARGET=OFF
        -DOPENMP_ENABLE_WERROR=OFF
        -DOPENMP_ENABLE_TESTING=OFF
        -DOPENMP_ENABLE_OMPT_TOOLS=OFF
        -DOPENMP_ENABLE_LIBOMP_PROFILING=OFF
        -DLIBOMP_ENABLE_SHARED=OFF
        -DLIBOMP_OMPT_SUPPORT=OFF
        -DLIBOMP_OMPT_BLAME=OFF
        -DLIBOMP_OMPT_TRACE=OFF
        -DLIBUNWIND_ENABLE_SHARED=OFF
        -DLIBUNWIND_ENABLE_STATIC=ON
        -DLIBUNWIND_ENABLE_CROSS_UNWINDING=OFF
        -DLIBUNWIND_ENABLE_ASSERTIONS=OFF
        -DLIBUNWIND_ENABLE_WERROR=OFF
        -DLIBUNWIND_ENABLE_PEDANTIC=OFF
        -DLIBUNWIND_ENABLE_THREADS=ON
        -DLIBUNWIND_ENABLE_EXCEPTIONS=ON
        -DLIBUNWIND_ENABLE_UNWIND_TABLES=ON
        -DLIBUNWIND_ENABLE_TERMINFO=OFF
    VALIDATION_FILES
        "${LLVM_PROJECT_INSTALL_DIR}/lib/libomp.a"
        "${LLVM_PROJECT_INSTALL_DIR}/lib/libunwind.a"
        "${LLVM_PROJECT_INSTALL_DIR}/include/omp.h"
        "${LLVM_PROJECT_INSTALL_DIR}/include/unwind.h"
)

# On Linux with libstdc++, we must avoid exposing LLVM's C++ ABI headers (cxxabi.h, etc.)
# which conflict with GCC's libstdc++ headers. We create a filtered include directory
# that only contains the OpenMP and libunwind headers we need.
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(_llvm_filtered_include_dir "${LLVM_PROJECT_INSTALL_DIR}/include_filtered")
    file(MAKE_DIRECTORY "${_llvm_filtered_include_dir}")
    
    # Copy only the headers we need (OpenMP and libunwind)
    set(_headers_to_copy "omp.h" "ompx.h" "unwind.h" "libunwind.h" "__libunwind_config.h")
    foreach(_header ${_headers_to_copy})
        if(EXISTS "${LLVM_PROJECT_INSTALL_DIR}/include/${_header}")
            file(COPY "${LLVM_PROJECT_INSTALL_DIR}/include/${_header}"
                 DESTINATION "${_llvm_filtered_include_dir}")
        endif()
    endforeach()
    
    set(_llvm_interface_include_dir "${_llvm_filtered_include_dir}")
else()
    # On macOS, we can use the full include directory safely
    set(_llvm_interface_include_dir "${LLVM_PROJECT_INSTALL_DIR}/include")
endif()

add_library(OpenMP::OpenMP_CXX STATIC IMPORTED GLOBAL)
set_target_properties(OpenMP::OpenMP_CXX PROPERTIES
  IMPORTED_LOCATION "${LLVM_PROJECT_INSTALL_DIR}/lib/libomp.a"
  INTERFACE_INCLUDE_DIRECTORIES "${_llvm_interface_include_dir}"
  INTERFACE_COMPILE_OPTIONS "-fopenmp=libomp"
  INTERFACE_LINK_DIRECTORIES "${LLVM_PROJECT_INSTALL_DIR}/lib"
)
add_library(OpenMP::OpenMP_C STATIC IMPORTED GLOBAL)
set_target_properties(OpenMP::OpenMP_C PROPERTIES
  IMPORTED_LOCATION "${LLVM_PROJECT_INSTALL_DIR}/lib/libomp.a"
  INTERFACE_INCLUDE_DIRECTORIES "${_llvm_interface_include_dir}"
  INTERFACE_COMPILE_OPTIONS "-fopenmp=libomp"
  INTERFACE_LINK_DIRECTORIES "${LLVM_PROJECT_INSTALL_DIR}/lib"
)
add_library(unwind::unwind STATIC IMPORTED GLOBAL)
set_target_properties(unwind::unwind PROPERTIES
  IMPORTED_LOCATION "${LLVM_PROJECT_INSTALL_DIR}/lib/libunwind.a"
  INTERFACE_INCLUDE_DIRECTORIES "${_llvm_interface_include_dir}"
)

if(APPLE)
  # Append (do not overwrite) any existing interface link options.
  get_target_property(_unwind_link_opts unwind::unwind INTERFACE_LINK_OPTIONS)
  if(NOT _unwind_link_opts)
    set(_unwind_link_opts "")
  endif()
  list(APPEND _unwind_link_opts "-Wl,-u,___unw_get_proc_name")
  set_target_properties(unwind::unwind PROPERTIES INTERFACE_LINK_OPTIONS "${_unwind_link_opts}")
  message(DEBUG "[libunwind] Ensured preservation of ___unw_get_proc_name on macOS")
endif()

if(NOT TARGET omp)
  add_library(omp ALIAS OpenMP::OpenMP_CXX)
endif()
if(NOT TARGET unwind)
  add_library(unwind ALIAS unwind::unwind)
endif()

# Set OpenMP variables for FindOpenMP module
set(OpenMP_FOUND TRUE CACHE BOOL "OpenMP found" FORCE)
set(OpenMP_C_FOUND TRUE CACHE BOOL "OpenMP C support found" FORCE)
set(OpenMP_CXX_FOUND TRUE CACHE BOOL "OpenMP CXX support found" FORCE)
set(OpenMP_VERSION "5.1" CACHE STRING "OpenMP version" FORCE)
set(OpenMP_C_VERSION "5.1" CACHE STRING "OpenMP C version" FORCE)
set(OpenMP_CXX_VERSION "5.1" CACHE STRING "OpenMP CXX version" FORCE)
# Pass linker search path to ensure we pick up our own libomp if implicit linking occurs
set(OpenMP_C_FLAGS "-fopenmp=libomp" CACHE STRING "OpenMP C flags" FORCE)
set(OpenMP_CXX_FLAGS "-fopenmp=libomp" CACHE STRING "OpenMP CXX flags" FORCE)
set(OpenMP_C_LIB_NAMES "omp" CACHE STRING "OpenMP C library names" FORCE)
set(OpenMP_CXX_LIB_NAMES "omp" CACHE STRING "OpenMP CXX library names" FORCE)
set(OpenMP_omp_LIBRARY "${LLVM_PROJECT_INSTALL_DIR}/lib/libomp.a" CACHE FILEPATH "OpenMP omp library" FORCE)

message(DEBUG "LLVM Project unified runtimes build (openmp;libunwind) complete")
