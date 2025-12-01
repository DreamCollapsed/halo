add_library(halo_common_base_lib
  Status.cpp
)

target_include_directories(halo_common_base_lib PUBLIC ${CMAKE_SOURCE_DIR}/src)

target_link_libraries(halo_common_base_lib
  PUBLIC
    halo_thirdparty_core
)

