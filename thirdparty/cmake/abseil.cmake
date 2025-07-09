# abseil third-party integration
# Reference: https://abseil.io/docs/cpp/tools/cmake-installs#initialize-your-project

# Set up directories
set(ABSEIL_NAME "abseil")
set(ABSEIL_DOWNLOAD_FILE "${THIRDPARTY_DOWNLOAD_DIR}/abseil-${ABSEIL_VERSION}.tar.gz")
set(ABSEIL_SOURCE_DIR "${THIRDPARTY_SRC_DIR}/${ABSEIL_NAME}")
set(ABSEIL_BUILD_DIR "${THIRDPARTY_BUILD_DIR}/${ABSEIL_NAME}")
set(ABSEIL_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/${ABSEIL_NAME}")

# Make sure the installation directory is absolute
get_filename_component(ABSEIL_INSTALL_DIR "${ABSEIL_INSTALL_DIR}" ABSOLUTE)

thirdparty_download_and_check("${ABSEIL_URL}" "${ABSEIL_DOWNLOAD_FILE}" "${ABSEIL_SHA256}")

thirdparty_extract_and_rename("${ABSEIL_DOWNLOAD_FILE}" "${ABSEIL_SOURCE_DIR}" "${THIRDPARTY_SRC_DIR}/abseil-cpp-*")

thirdparty_cmake_configure("${ABSEIL_SOURCE_DIR}" "${ABSEIL_BUILD_DIR}"
    VALIDATION_FILES
        "${ABSEIL_BUILD_DIR}/CMakeCache.txt"
        "${ABSEIL_BUILD_DIR}/Makefile"
        "${ABSEIL_BUILD_DIR}/lib/cmake/absl/abslTargets.cmake"
    -DCMAKE_INSTALL_PREFIX="${ABSEIL_INSTALL_DIR}"
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON)

thirdparty_cmake_install("${ABSEIL_BUILD_DIR}" "${ABSEIL_INSTALL_DIR}"
    VALIDATION_FILES
        "${ABSEIL_INSTALL_DIR}/lib/cmake/absl/abslConfig.cmake"
        "${ABSEIL_INSTALL_DIR}/lib/libabsl_strings.a"
        "${ABSEIL_INSTALL_DIR}/include/absl/strings/string_view.h")

# Export abseil to global scope
if(EXISTS "${ABSEIL_INSTALL_DIR}/lib/cmake/absl/abslConfig.cmake")
    list(APPEND CMAKE_PREFIX_PATH "${ABSEIL_INSTALL_DIR}")
    set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" PARENT_SCOPE)
    set(absl_DIR "${ABSEIL_INSTALL_DIR}/lib/cmake/absl" CACHE PATH "Path to installed abseil cmake config" FORCE)
    message(STATUS "Abseil found and exported globally: ${ABSEIL_INSTALL_DIR}")
else()
    message(WARNING "Abseil installation not found at ${ABSEIL_INSTALL_DIR}")
endif()
