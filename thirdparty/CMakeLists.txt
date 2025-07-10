# Load common component information and utility functions
include(ComponentsInfo.cmake)
include(ThirdpartyUtils.cmake)

# Create required directories
file(MAKE_DIRECTORY ${THIRDPARTY_DOWNLOAD_DIR})
file(MAKE_DIRECTORY ${THIRDPARTY_SRC_DIR})
file(MAKE_DIRECTORY ${THIRDPARTY_BUILD_DIR})
file(MAKE_DIRECTORY ${THIRDPARTY_INSTALL_DIR})

# Integrate third-party libraries
include(cmake/abseil.cmake)
include(cmake/gtest.cmake)
include(cmake/gflags.cmake)

# Create centralized third-party targets
# This eliminates the need for find_package calls throughout the project

# Find all packages after they have been built and installed
find_package(absl REQUIRED CONFIG)
find_package(GTest REQUIRED CONFIG)
find_package(gflags REQUIRED CONFIG)

# Create a main third-party interface target for production code
add_library(halo_thirdparty INTERFACE)
add_library(halo::thirdparty ALIAS halo_thirdparty)

# Link core libraries needed by production code (static versions)
target_link_libraries(halo_thirdparty
    INTERFACE
    absl::strings
    absl::str_format
    absl::flat_hash_map
    absl::hash
    absl::time
    absl::civil_time
    absl::status
    absl::statusor
)

# Create a test-specific third-party interface target
add_library(halo_thirdparty_test INTERFACE)
add_library(halo::thirdparty_test ALIAS halo_thirdparty_test)

# Link all libraries needed by tests (static versions)
target_link_libraries(halo_thirdparty_test
    INTERFACE
    GTest::gtest
    GTest::gtest_main
    GTest::gmock
    GTest::gmock_main
    gflags_static
)

# Export targets to parent scope for global availability
set_target_properties(halo_thirdparty PROPERTIES EXPORT_NAME thirdparty)
set_target_properties(halo_thirdparty_test PROPERTIES EXPORT_NAME thirdparty_test)
