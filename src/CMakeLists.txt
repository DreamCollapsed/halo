# 添加可执行文件
add_executable(myapp main.cpp)

# 设置包含目录
target_include_directories(myapp PRIVATE
    ${THIRDPARTY_INSTALL_DIR}/include
)

# 设置链接目录
target_link_directories(myapp PRIVATE
    ${THIRDPARTY_INSTALL_DIR}/lib
)

# 基本库列表
set(BASIC_LIBS
    folly
    fmt
    double-conversion
    gflags
    glog
    ${THIRDPARTY_INSTALL_DIR}/lib/libboost_context.a
    ${THIRDPARTY_INSTALL_DIR}/lib/libboost_filesystem.a
    ${THIRDPARTY_INSTALL_DIR}/lib/libboost_program_options.a
    ${THIRDPARTY_INSTALL_DIR}/lib/libboost_system.a
    ${THIRDPARTY_INSTALL_DIR}/lib/libboost_thread.a
    ${THIRDPARTY_INSTALL_DIR}/lib/libssl.a
    ${THIRDPARTY_INSTALL_DIR}/lib/libcrypto.a
    ${THIRDPARTY_INSTALL_DIR}/lib/libevent.a
    ${THIRDPARTY_INSTALL_DIR}/lib/libz.a
)

# 系统特定的库
if(NOT APPLE)
    list(APPEND BASIC_LIBS
        ${THIRDPARTY_INSTALL_DIR}/lib/libunwind.a
        ${THIRDPARTY_INSTALL_DIR}/lib/libdw.a
        ${THIRDPARTY_INSTALL_DIR}/lib/libelf.a
    )
endif()

# 链接所需的库
target_link_libraries(myapp PRIVATE
    ${BASIC_LIBS}
    pthread
    dl
)

if(APPLE)
    # macOS 特定的系统框架
    target_link_libraries(myapp PRIVATE
        "-framework CoreFoundation"
        "-framework Security"
    )
endif() 