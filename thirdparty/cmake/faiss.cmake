# FAISS third-party integration
# Reference: https://github.com/facebookresearch/faiss

thirdparty_setup_directories("faiss")

thirdparty_build_cmake_library(faiss
    CMAKE_ARGS
        -DFAISS_ENABLE_GPU=OFF
        -DFAISS_ENABLE_PYTHON=OFF
        -DFAISS_ENABLE_CUVS=OFF
        -DFAISS_ENABLE_C_API=ON
        -DCMAKE_BUILD_TYPE=Release
        -DFAISS_OPT_LEVEL=sve
        -DFAISS_USE_LTO=ON
    VALIDATION_FILES
        "${FAISS_INSTALL_DIR}/lib/libfaiss.a"
)

find_package(faiss CONFIG REQUIRED)
message(STATUS "faiss package imported via CMake configs: ${faiss_DIR}")
