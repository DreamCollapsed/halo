# LLVM Project third-party integration
# Build OpenMP and libunwind runtimes using CMAKE_CACHE_ARGS to handle semicolons

thirdparty_setup_directories("llvm-project")

thirdparty_build_cmake_library(llvm-project
    SOURCE_SUBDIR "runtimes"
    CMAKE_CACHE_ARGS
        "LLVM_ENABLE_RUNTIMES=openmp;libunwind"
        "CLANG_VERSION_MAJOR=20"
        "PACKAGE_VERSION=20.1.8"
        "CLANG_RESOURCE_DIR=20"
        "CMAKE_CXX_FLAGS=-I${THIRDPARTY_BUILD_DIR}/llvm-project/bin/20/include"
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

add_library(OpenMP::OpenMP_CXX STATIC IMPORTED GLOBAL)
set_target_properties(OpenMP::OpenMP_CXX PROPERTIES
  IMPORTED_LOCATION "${LLVM_PROJECT_INSTALL_DIR}/lib/libomp.a"
  INTERFACE_INCLUDE_DIRECTORIES "${LLVM_PROJECT_INSTALL_DIR}/include"
  INTERFACE_COMPILE_OPTIONS "-fopenmp=libomp"
)
add_library(OpenMP::OpenMP_C STATIC IMPORTED GLOBAL)
set_target_properties(OpenMP::OpenMP_C PROPERTIES
  IMPORTED_LOCATION "${LLVM_PROJECT_INSTALL_DIR}/lib/libomp.a"
  INTERFACE_INCLUDE_DIRECTORIES "${LLVM_PROJECT_INSTALL_DIR}/include"
  INTERFACE_COMPILE_OPTIONS "-fopenmp=libomp"
)
add_library(unwind::unwind STATIC IMPORTED GLOBAL)
set_target_properties(unwind::unwind PROPERTIES
  IMPORTED_LOCATION "${LLVM_PROJECT_INSTALL_DIR}/lib/libunwind.a"
  INTERFACE_INCLUDE_DIRECTORIES "${LLVM_PROJECT_INSTALL_DIR}/include"
)
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
set(OpenMP_VERSION "5.0" CACHE STRING "OpenMP version" FORCE)
set(OpenMP_C_VERSION "5.0" CACHE STRING "OpenMP C version" FORCE)
set(OpenMP_CXX_VERSION "5.0" CACHE STRING "OpenMP CXX version" FORCE)
set(OpenMP_C_FLAGS "-fopenmp=libomp" CACHE STRING "OpenMP C flags" FORCE)
set(OpenMP_CXX_FLAGS "-fopenmp=libomp" CACHE STRING "OpenMP CXX flags" FORCE)
set(OpenMP_C_LIB_NAMES "omp" CACHE STRING "OpenMP C library names" FORCE)
set(OpenMP_CXX_LIB_NAMES "omp" CACHE STRING "OpenMP CXX library names" FORCE)
set(OpenMP_omp_LIBRARY "${LLVM_PROJECT_INSTALL_DIR}/lib/libomp.a" CACHE FILEPATH "OpenMP omp library" FORCE)

# Copy OpenMP headers to standard include directory for better compatibility
file(MAKE_DIRECTORY "${LLVM_PROJECT_INSTALL_DIR}/include")
if(EXISTS "${LLVM_PROJECT_INSTALL_DIR}/bin/20/include/omp.h")
    file(COPY "${LLVM_PROJECT_INSTALL_DIR}/bin/20/include/omp.h" 
         DESTINATION "${LLVM_PROJECT_INSTALL_DIR}/include")
endif()
if(EXISTS "${LLVM_PROJECT_INSTALL_DIR}/bin/20/include/ompx.h")
    file(COPY "${LLVM_PROJECT_INSTALL_DIR}/bin/20/include/ompx.h" 
         DESTINATION "${LLVM_PROJECT_INSTALL_DIR}/include")
endif()

message(DEBUG "LLVM Project unified runtimes build (openmp;libunwind) complete")
