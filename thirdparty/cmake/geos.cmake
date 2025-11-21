# GEOS (Geometry Engine - Open Source) third-party integration
# Reference: https://libgeos.org/
# We build static libraries libgeos.a and libgeos_c.a
# GEOS 3.13.x uses CMake build system.

# Build GEOS using the generic CMake helper.
# Important CMake options:
#   -DBUILD_SHARED_LIBS=OFF (already provided by optimization flags)
#   -DGEOS_BUILD_TESTS=OFF
#   -DGEOS_BUILD_BENCHMARKS=OFF
#   -DGEOS_ENABLE_TESTS=OFF (legacy variable guard)
#   -DGEOS_USE_ONLY_RINT=ON (optional smaller build; keep default OFF)
# We validate install by checking for static libs and geos_c.h header.

thirdparty_build_cmake_library("geos"
    CMAKE_ARGS
        -DGEOS_BUILD_TESTS=OFF
        -DGEOS_BUILD_BENCHMARKS=OFF
        -DGEOS_ENABLE_TESTS=OFF
        -DBUILD_GEOSOP=OFF
    FILE_REPLACEMENTS
        "include/geos/operation/overlay/snap/SnapOverlayOp.h"
        "#include <geos/operation/overlay/OverlayOp.h> // for enums"
        "#include <geos/operation/overlay/OverlayOp.h> // for enums\n#include <geos/geom/Geometry.h> // for complete type definition required by unique_ptr in C++23"
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/geos/lib/libgeos.a"
        "${THIRDPARTY_INSTALL_DIR}/geos/lib/libgeos_c.a"
        "${THIRDPARTY_INSTALL_DIR}/geos/include/geos_c.h"
)

find_package(GEOS CONFIG REQUIRED)

thirdparty_map_imported_config(GEOS::geos GEOS::geos_c)
