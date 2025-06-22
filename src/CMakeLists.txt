add_executable(folly_test main.cpp)

target_include_directories(folly_test
    PRIVATE
    ${THIRDPARTY_INSTALL_DIR}/include
)

target_link_directories(folly_test
    PRIVATE
    ${THIRDPARTY_INSTALL_DIR}/lib
)

target_link_libraries(folly_test
    PRIVATE
    folly
    glog
    gflags
    event
    double-conversion
    fmt
    boost_context
    boost_chrono
    boost_date_time
    boost_filesystem
    boost_program_options
    boost_regex
    boost_system
    boost_thread
    unwind
)
