# Define base paths relative to current directory
set(THIRDPARTY_BASE_DIR ${CMAKE_CURRENT_SOURCE_DIR})

set(THIRDPARTY_DOWNLOAD_DIR ${THIRDPARTY_BASE_DIR}/downloads)
set(THIRDPARTY_SRC_DIR ${THIRDPARTY_BASE_DIR}/src)
set(THIRDPARTY_BUILD_DIR ${THIRDPARTY_BASE_DIR}/builds)
set(THIRDPARTY_INSTALL_DIR ${THIRDPARTY_BASE_DIR}/installed)

include(ComponentsInfo.cmake)
include(ThirdpartyUtils.cmake)
include(ThirdpartyDependencies.cmake)

thirdparty_setup_ccache()

file(MAKE_DIRECTORY ${THIRDPARTY_DOWNLOAD_DIR})
file(MAKE_DIRECTORY ${THIRDPARTY_SRC_DIR})
file(MAKE_DIRECTORY ${THIRDPARTY_BUILD_DIR})
file(MAKE_DIRECTORY ${THIRDPARTY_INSTALL_DIR})

thirdparty_show_dependencies()

thirdparty_compute_build_order(_build_order)
message(STATUS "Building components in order: ${_build_order}")

set(_build_start_time "${CMAKE_CURRENT_LIST_FILE}")
foreach(_component IN LISTS _build_order)
    message(STATUS "Processing component: ${_component}")
    
    # Record start time for this component
    string(TIMESTAMP _component_start_time "%s")
    
    include(cmake/${_component}.cmake)
    
    # Record end time and calculate build time
    string(TIMESTAMP _component_end_time "%s")
    math(EXPR _component_duration "${_component_end_time} - ${_component_start_time}")
    message(STATUS "Component ${_component} processed in ${_component_duration} seconds")
endforeach()

# Display build summary
message(STATUS "=== Third-party Build Summary ===")
thirdparty_get_build_jobs(OUTPUT_COMPILE_JOBS _compile_jobs OUTPUT_LINK_JOBS _link_jobs OUTPUT_MAKE_JOBS _make_jobs)
message(STATUS "Build job configuration: compile=${_compile_jobs}, link=${_link_jobs}, make=${_make_jobs}")

thirdparty_get_ccache_executable(_ccache_path)
if(_ccache_path)
    message(STATUS "Ccache: ENABLED (${_ccache_path})")
else()
    message(STATUS "Ccache: NOT AVAILABLE")
endif()

find_program(NINJA_EXECUTABLE ninja)
if(NINJA_EXECUTABLE)
    message(STATUS "Build generator: Ninja (${NINJA_EXECUTABLE})")
else()
    message(STATUS "Build generator: ${CMAKE_GENERATOR}")
endif()

add_library(halo_thirdparty INTERFACE)
add_library(halo::thirdparty ALIAS halo_thirdparty)
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
    Boost::system
    Boost::filesystem
    Boost::thread
    Boost::chrono
    Boost::date_time
    Boost::regex
    Boost::program_options
    Boost::iostreams
    Boost::random
    Boost::context
    Boost::coroutine
    Boost::atomic
    Boost::container
    Boost::log
    Boost::timer
    Boost::serialization
    Boost::math
    Boost::json
    Boost::stacktrace_basic
    Boost::url
    Boost::wave
    Boost::fiber
    Boost::exception
    Boost::graph
    gflags::gflags_static
    glog::glog
    double-conversion::double-conversion
    FastFloat::fast_float
    fmt::fmt
    jemalloc::jemalloc_pic
    zstd::libzstd_static
    LZ4::lz4_static
    liblzma::liblzma
    Snappy::snappy
    OpenSSL::SSL
    OpenSSL::Crypto
    libevent::core
    libevent::extra
    libevent::openssl
    libevent::pthreads
    ICU::ICU
    zlib::zlib
    BZip2::BZip2
    Folly::folly
    libsodium::libsodium
    libstemmer::libstemmer
    protobuf::libprotobuf
    thrift::thrift
    thriftz::thriftz
    xxhash::xxhash
    fizz::fizz
)

add_library(halo_thirdparty_test INTERFACE)
add_library(halo::thirdparty_test ALIAS halo_thirdparty_test)
target_link_libraries(halo_thirdparty_test
    INTERFACE
    GTest::gtest
    GTest::gtest_main
    GTest::gmock
    GTest::gmock_main
)

set_target_properties(halo_thirdparty PROPERTIES EXPORT_NAME thirdparty)
set_target_properties(halo_thirdparty_test PROPERTIES EXPORT_NAME thirdparty_test)
