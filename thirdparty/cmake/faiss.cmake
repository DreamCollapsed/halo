# FAISS third-party integration
# Reference: https://github.com/facebookresearch/faiss

thirdparty_setup_directories("faiss")

# Get OpenMP path from llvm-project dependency
set(_openmp_dir "${THIRDPARTY_INSTALL_DIR}/llvm-project")

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
        "OpenMP_CXX_INCLUDE_DIR=${_openmp_dir}/include"
    CMAKE_ARGS
        -DFAISS_ENABLE_GPU=OFF
        -DFAISS_ENABLE_PYTHON=OFF
        -DFAISS_ENABLE_CUVS=OFF
        -DFAISS_ENABLE_C_API=ON
        -DCMAKE_BUILD_TYPE=Release
        -DFAISS_OPT_LEVEL=sve
        -DFAISS_USE_LTO=ON
        # Point to our OpenMP installation - these are checked by FindOpenMP
        -DOpenMP_ROOT=${_openmp_dir}
        -DOpenMP_CXX_INCLUDE_DIRS=${_openmp_dir}/include
        # Add OpenMP include directory to compiler flags
        -DCMAKE_CXX_FLAGS=-I${_openmp_dir}/include
    VALIDATION_FILES
        "${FAISS_INSTALL_DIR}/lib/libfaiss.a"
)

find_package(faiss CONFIG REQUIRED)
