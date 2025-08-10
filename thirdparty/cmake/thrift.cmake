# Apache Thrift integration for the Halo project
# This file handles downloading, building, and installing Apache Thrift

thirdparty_setup_directories("thrift")

thirdparty_download_and_check("${THRIFT_URL}" "${THRIFT_DOWNLOAD_FILE}" "${THRIFT_SHA256}")
thirdparty_extract_and_rename("${THRIFT_DOWNLOAD_FILE}" "${THRIFT_SOURCE_DIR}" "${THIRDPARTY_SRC_DIR}/${THRIFT_NAME}-*")

set(THRIFT_TSSL_FILE "${THRIFT_SOURCE_DIR}/lib/cpp/src/thrift/transport/TSSLSocket.cpp")
if(EXISTS "${THRIFT_TSSL_FILE}")
    message(STATUS "Applying OpenSSL compatibility fixes to TSSLSocket.cpp")
    file(READ "${THRIFT_TSSL_FILE}" THRIFT_FILE_CONTENT)
    
    # Fix CRYPTO_num_locks() for OpenSSL 1.1+
    string(REPLACE 
        "mutexes = boost::shared_array<Mutex>(new Mutex[ ::CRYPTO_num_locks()]);"
        "#if OPENSSL_VERSION_NUMBER < 0x10100000L\n  mutexes = boost::shared_array<Mutex>(new Mutex[CRYPTO_num_locks()]);\n#else\n  // OpenSSL 1.1.0+ handles locking internally\n  mutexes = boost::shared_array<Mutex>(new Mutex[1]);\n#endif"
        THRIFT_FILE_CONTENT "${THRIFT_FILE_CONTENT}")
    
    # Fix CRYPTO_LOCK usage
    string(REPLACE 
        "if (mode & CRYPTO_LOCK) {"
        "#if OPENSSL_VERSION_NUMBER < 0x10100000L\n  if (mode & CRYPTO_LOCK) {\n#else\n  if (mode & 1) {\n#endif"
        THRIFT_FILE_CONTENT "${THRIFT_FILE_CONTENT}")
    
    # Fix SSL initialization functions
    string(REPLACE 
        "SSL_library_init();\n  SSL_load_error_strings();\n  ERR_load_crypto_strings();"
        "#if OPENSSL_VERSION_NUMBER < 0x10100000L\n  SSL_library_init();\n  SSL_load_error_strings();\n  ERR_load_crypto_strings();\n#else\n  OPENSSL_init_ssl(0, NULL);\n  OPENSSL_init_crypto(0, NULL);\n#endif"
        THRIFT_FILE_CONTENT "${THRIFT_FILE_CONTENT}")
    
    # Fix CRYPTO locking callbacks
    string(REPLACE 
        "CRYPTO_set_locking_callback(callbackLocking);\n\n  // dynamic locking\n  CRYPTO_set_dynlock_create_callback(dyn_create);\n  CRYPTO_set_dynlock_lock_callback(dyn_lock);\n  CRYPTO_set_dynlock_destroy_callback(dyn_destroy);"
        "#if OPENSSL_VERSION_NUMBER < 0x10100000L\n  CRYPTO_set_locking_callback(callbackLocking);\n\n  // dynamic locking\n  CRYPTO_set_dynlock_create_callback(dyn_create);\n  CRYPTO_set_dynlock_lock_callback(dyn_lock);\n  CRYPTO_set_dynlock_destroy_callback(dyn_destroy);\n#endif"
        THRIFT_FILE_CONTENT "${THRIFT_FILE_CONTENT}")
    
    # Fix SSL cleanup functions - more comprehensive patterns
    string(REPLACE 
        "EVP_cleanup();\n  CRYPTO_cleanup_all_ex_data();"
        "#if OPENSSL_VERSION_NUMBER < 0x10100000L\n  EVP_cleanup();\n  CRYPTO_cleanup_all_ex_data();\n#else\n  // OpenSSL 1.1.0+ cleans up automatically\n#endif"
        THRIFT_FILE_CONTENT "${THRIFT_FILE_CONTENT}")
    
    string(REPLACE 
        "ERR_free_strings();"
        "#if OPENSSL_VERSION_NUMBER < 0x10100000L\n  ERR_free_strings();\n#endif"
        THRIFT_FILE_CONTENT "${THRIFT_FILE_CONTENT}")
    
    string(REPLACE 
        "CRYPTO_set_locking_callback(nullptr);\n  CRYPTO_set_dynlock_create_callback(nullptr);\n  CRYPTO_set_dynlock_lock_callback(nullptr);\n  CRYPTO_set_dynlock_destroy_callback(nullptr);"
        "#if OPENSSL_VERSION_NUMBER < 0x10100000L\n  CRYPTO_set_locking_callback(nullptr);\n  CRYPTO_set_dynlock_create_callback(nullptr);\n  CRYPTO_set_dynlock_lock_callback(nullptr);\n  CRYPTO_set_dynlock_destroy_callback(nullptr);\n#endif"
        THRIFT_FILE_CONTENT "${THRIFT_FILE_CONTENT}")
    
    # Fix deprecated SSL method functions
    string(REPLACE 
        "ctx_ = SSL_CTX_new(TLSv1_method());"
        "#if OPENSSL_VERSION_NUMBER < 0x10100000L\n    ctx_ = SSL_CTX_new(TLSv1_method());\n#else\n    ctx_ = SSL_CTX_new(TLS_method());\n    SSL_CTX_set_min_proto_version(ctx_, TLS1_VERSION);\n    SSL_CTX_set_max_proto_version(ctx_, TLS1_VERSION);\n#endif"
        THRIFT_FILE_CONTENT "${THRIFT_FILE_CONTENT}")
    
    string(REPLACE 
        "ctx_ = SSL_CTX_new(TLSv1_1_method());"
        "#if OPENSSL_VERSION_NUMBER < 0x10100000L\n    ctx_ = SSL_CTX_new(TLSv1_1_method());\n#else\n    ctx_ = SSL_CTX_new(TLS_method());\n    SSL_CTX_set_min_proto_version(ctx_, TLS1_1_VERSION);\n    SSL_CTX_set_max_proto_version(ctx_, TLS1_1_VERSION);\n#endif"
        THRIFT_FILE_CONTENT "${THRIFT_FILE_CONTENT}")
    
    string(REPLACE 
        "ctx_ = SSL_CTX_new(TLSv1_2_method());"
        "#if OPENSSL_VERSION_NUMBER < 0x10100000L\n    ctx_ = SSL_CTX_new(TLSv1_2_method());\n#else\n    ctx_ = SSL_CTX_new(TLS_method());\n    SSL_CTX_set_min_proto_version(ctx_, TLS1_2_VERSION);\n    SSL_CTX_set_max_proto_version(ctx_, TLS1_2_VERSION);\n#endif"
        THRIFT_FILE_CONTENT "${THRIFT_FILE_CONTENT}")
    
    # Fix ASN1_STRING_data deprecation
    string(REPLACE 
        "char* data = (char*)ASN1_STRING_data(name->d.ia5);"
        "#if OPENSSL_VERSION_NUMBER < 0x10100000L\n        char* data = (char*)ASN1_STRING_data(name->d.ia5);\n#else\n        char* data = (char*)ASN1_STRING_get0_data(name->d.ia5);\n#endif"
        THRIFT_FILE_CONTENT "${THRIFT_FILE_CONTENT}")
    
    file(WRITE "${THRIFT_TSSL_FILE}" "${THRIFT_FILE_CONTENT}")
    message(STATUS "OpenSSL compatibility fixes applied successfully")
endif()

thirdparty_get_optimization_flags(THRIFT_CMAKE_ARGS COMPONENT "${THRIFT_NAME}")
thirdparty_cmake_configure("${THRIFT_SOURCE_DIR}" "${THRIFT_BUILD_DIR}"
    VALIDATION_FILES
        "${THRIFT_BUILD_DIR}/Makefile"
        "${THRIFT_BUILD_DIR}/build.ninja"
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${THRIFT_INSTALL_DIR}
        ${THRIFT_CMAKE_ARGS}
        -DBUILD_TUTORIALS=OFF
        -DBUILD_EXAMPLES=OFF
        -DWITH_QT5=OFF
        -DWITH_QT6=OFF
        -DWITH_JAVA=OFF
        -DWITH_PYTHON=OFF
        -DWITH_JAVASCRIPT=OFF
        -DWITH_NODEJS=OFF
        -DWITH_CPP=ON
        -DWITH_C_GLIB=OFF
        -DWITH_LIBEVENT=OFF
        -DWITH_OPENSSL=ON
        -DWITH_ZLIB=ON
        -DBoost_USE_STATIC_LIBS=ON
        -DBoost_ROOT=${THIRDPARTY_INSTALL_DIR}/boost
        -DZLIB_ROOT=${THIRDPARTY_INSTALL_DIR}/zlib
        -DZLIB_LIBRARY=${THIRDPARTY_INSTALL_DIR}/zlib/lib/libz.a
        -DZLIB_INCLUDE_DIR=${THIRDPARTY_INSTALL_DIR}/zlib/include
        -DOPENSSL_ROOT_DIR=${THIRDPARTY_INSTALL_DIR}/openssl
        -DOPENSSL_INCLUDE_DIR=${THIRDPARTY_INSTALL_DIR}/openssl/include
        -DOPENSSL_SSL_LIBRARY=${THIRDPARTY_INSTALL_DIR}/openssl/lib/libssl.a
        -DOPENSSL_CRYPTO_LIBRARY=${THIRDPARTY_INSTALL_DIR}/openssl/lib/libcrypto.a
        -DBISON_EXECUTABLE=${THIRDPARTY_INSTALL_DIR}/bison/bin/bison
        -DFLEX_EXECUTABLE=${THIRDPARTY_INSTALL_DIR}/flex/bin/flex
)

thirdparty_cmake_install("${THRIFT_BUILD_DIR}" "${THRIFT_INSTALL_DIR}"
    VALIDATION_FILES 
        "${THRIFT_INSTALL_DIR}/lib/libthrift.a"
        "${THRIFT_INSTALL_DIR}/lib/libthriftz.a"
        "${THRIFT_INSTALL_DIR}/include/thrift/Thrift.h"
        "${THRIFT_INSTALL_DIR}/include/thrift/transport/TSSLSocket.h"
        "${THRIFT_INSTALL_DIR}/bin/thrift"
)

get_filename_component(THRIFT_INSTALL_DIR "${THRIFT_INSTALL_DIR}" ABSOLUTE)

if(NOT TARGET thrift::thrift)
    find_package(thrift CONFIG REQUIRED)
    
    if(NOT TARGET thrift::thrift)
        add_library(thrift::thrift STATIC IMPORTED GLOBAL)
        set_target_properties(thrift::thrift PROPERTIES
            IMPORTED_LOCATION "${THRIFT_INSTALL_DIR}/lib/libthrift.a"
            INTERFACE_INCLUDE_DIRECTORIES "${THRIFT_INSTALL_DIR}/include"
            INTERFACE_LINK_LIBRARIES "Boost::boost;OpenSSL::SSL;OpenSSL::Crypto;ZLIB::ZLIB"
        )
        
        if(EXISTS "${THRIFT_INSTALL_DIR}/lib/libthriftz.a")
            add_library(thrift::thriftz STATIC IMPORTED GLOBAL)
            set_target_properties(thrift::thriftz PROPERTIES
                IMPORTED_LOCATION "${THRIFT_INSTALL_DIR}/lib/libthriftz.a"
                INTERFACE_INCLUDE_DIRECTORIES "${THRIFT_INSTALL_DIR}/include"
                INTERFACE_LINK_LIBRARIES "thrift::thrift;ZLIB::ZLIB"
            )
        endif()
        
        message(STATUS "Created thrift::thrift target manually")
    else()
        message(STATUS "Found thrift package with thrift::thrift target")
    endif()
endif()

message(STATUS "Finished building ${THRIFT_NAME}. Installed at: ${THRIFT_INSTALL_DIR}")
