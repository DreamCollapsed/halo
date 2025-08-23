# RapidJSON third-party integration (header-only)
# Reference: https://github.com/Tencent/rapidjson

thirdparty_setup_directories("rapidjson")

list(APPEND _opt_flags
    -DCMAKE_INSTALL_PREFIX=${RAPIDJSON_INSTALL_DIR}
    -DRAPIDJSON_BUILD_TESTS=OFF
    -DRAPIDJSON_BUILD_EXAMPLES=OFF
    -DRAPIDJSON_BUILD_DOC=OFF
)

thirdparty_build_cmake_library("rapidjson"
    CMAKE_ARGS ${_opt_flags}
    VALIDATION_FILES
        "${RAPIDJSON_INSTALL_DIR}/include/rapidjson/document.h"
)

find_package(RapidJSON CONFIG REQUIRED)
# if(NOT TARGET RapidJSON::rapidjson)
#     set(_rapidjson_includes "${RAPIDJSON_INSTALL_DIR}/include")
#     if(RapidJSON_FOUND)
#         if(DEFINED RapidJSON_INCLUDE_DIRS)
#             set(_rapidjson_includes "${RapidJSON_INCLUDE_DIRS}")
#         elseif(DEFINED RapidJSON_INCLUDE_DIR)
#             set(_rapidjson_includes "${RapidJSON_INCLUDE_DIR}")
#         endif()
#     endif()
#     add_library(RapidJSON::rapidjson INTERFACE IMPORTED)
#     set_target_properties(RapidJSON::rapidjson PROPERTIES
#         INTERFACE_INCLUDE_DIRECTORIES "${_rapidjson_includes}"
#     )
# endif()
