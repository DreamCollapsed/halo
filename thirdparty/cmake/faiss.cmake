# FAISS third-party integration
# Reference: https://github.com/facebookresearch/faiss

thirdparty_setup_directories("faiss")

# Get OpenMP path from llvm-project dependency
set(_openmp_dir "${THIRDPARTY_INSTALL_DIR}/llvm-project")

# On Linux with libstdc++, use the filtered include directory to avoid conflicts
if(UNIX AND NOT APPLE)
    set(_openmp_include_dir "${_openmp_dir}/include_filtered")
else()
    set(_openmp_include_dir "${_openmp_dir}/include")
endif()

###############################################################################
# Auto-select FAISS_OPT_LEVEL for the limited set of platforms we care about.
# Scope (only these three cases):
#   1. Apple Silicon (arm64) -> arm64
#   2. Linux x86_64          -> avx2
#   3. Linux arm64/aarch64   -> arm64
# Anything else -> generic
# No manual override variable to keep it simple.
###############################################################################
if(APPLE AND CMAKE_SYSTEM_PROCESSOR MATCHES "arm64|aarch64")
    set(_faiss_opt_level "arm64")
elseif(UNIX AND CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64")
    set(_faiss_opt_level "avx2")
elseif(UNIX AND CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|ARM64")
    set(_faiss_opt_level "arm64")
else()
    set(_faiss_opt_level "generic")
endif()
message(DEBUG "[faiss] Auto FAISS_OPT_LEVEL='${_faiss_opt_level}' (Apple arm64 -> arm64; Linux x86_64 -> avx2; Linux arm64 -> arm64; other -> generic)")

thirdparty_combine_flags(_faiss_cxx_flags FRAGMENTS "${HALO_CMAKE_CXX_FLAGS_BASE}" "-I${_openmp_include_dir}")

thirdparty_build_cmake_library(faiss
    CMAKE_CACHE_ARGS
        # Pass OpenMP configuration explicitly to child CMake process
        "OpenMP_FOUND=TRUE"
        "OpenMP_C_FOUND=TRUE"
        "OpenMP_CXX_FOUND=TRUE"
        "OpenMP_VERSION=5.0"
        "OpenMP_C_VERSION=5.0"
        "OpenMP_CXX_VERSION=5.0"
        "OpenMP_C_FLAGS=-fopenmp=libomp"
        "OpenMP_CXX_FLAGS=-fopenmp=libomp"
        "OpenMP_C_LIB_NAMES=omp"
        "OpenMP_CXX_LIB_NAMES=omp"
        "OpenMP_omp_LIBRARY=${_openmp_dir}/lib/libomp.a"
        "OpenMP_CXX_INCLUDE_DIR=${_openmp_include_dir}"
    CMAKE_ARGS
        -DFAISS_ENABLE_GPU=OFF
        -DFAISS_ENABLE_PYTHON=OFF
        -DFAISS_ENABLE_CUVS=OFF
        -DFAISS_ENABLE_C_API=ON
        -DCMAKE_BUILD_TYPE=Release
        -DFAISS_OPT_LEVEL=${_faiss_opt_level}
        -DFAISS_USE_LTO=OFF
        # Point to our OpenMP installation - these are checked by FindOpenMP
        -DOpenMP_ROOT=${_openmp_dir}
        -DOpenMP_CXX_INCLUDE_DIRS=${_openmp_include_dir}
        # Use safely combined CMAKE_CXX_FLAGS
        -DCMAKE_CXX_FLAGS=${_faiss_cxx_flags}
    VALIDATION_FILES
        "${FAISS_INSTALL_DIR}/lib/libfaiss.a"
)

find_package(faiss CONFIG REQUIRED)
