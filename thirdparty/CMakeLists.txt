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
    include(cmake/${_component}.cmake)
endforeach()

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

add_library(halo_thirdparty_core INTERFACE)
target_link_libraries(halo_thirdparty_core
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
    xxhash::xxhash
    fizz::fizz
    wangle::wangle
    mvfst::mvfst_transport
    gRPC::grpc
    gRPC::grpc++
    c-ares::cares
    faiss
    xsimd
    xtl
    RapidJSON
    re2::re2
    utf8proc::halo_utf8proc
    GEOS::geos
    GEOS::geos_c
    simdjson::simdjson
    OpenMP::OpenMP_CXX
    unwind::unwind
)

add_library(halo_thirdparty_with_thrift INTERFACE)
target_link_libraries(halo_thirdparty_with_thrift
    INTERFACE
    thrift::thrift
    thriftz::thriftz
    Arrow::arrow
    ArrowAcero::arrow_acero
    ArrowCompute::arrow_compute
    ArrowDataset::arrow_dataset
    ArrowFlight::arrow_flight
    ArrowFlightSql::arrow_flight_sql
    ArrowSubstrait::arrow_substrait
    Gandiva::gandiva
    Parquet::parquet
)

add_library(halo_thirdparty_with_fbthrift INTERFACE)
target_link_libraries(halo_thirdparty_with_fbthrift
    INTERFACE
    FBThrift::thriftcpp2
)

add_library(halo_thirdparty_test INTERFACE)
target_link_libraries(halo_thirdparty_test
    INTERFACE
    GTest::gtest
    GTest::gtest_main
    GTest::gmock
    GTest::gmock_main
)

thirdparty_get_executable_definitions(_executable_definitions)
target_compile_definitions(halo_thirdparty_core 
    INTERFACE 
    ${_executable_definitions}
)
target_compile_definitions(halo_thirdparty_with_thrift 
    INTERFACE 
    ${_executable_definitions}
)
target_compile_definitions(halo_thirdparty_with_fbthrift 
    INTERFACE 
    ${_executable_definitions}
)
target_compile_definitions(halo_thirdparty_test 
    INTERFACE 
    ${_executable_definitions}
)
