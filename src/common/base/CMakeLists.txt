add_library(halo_common_base)
target_sources(halo_common_base
  PUBLIC
    FILE_SET CXX_MODULES FILES
      Status.cppm
      StatusOr.cppm
      common.cppm
)
