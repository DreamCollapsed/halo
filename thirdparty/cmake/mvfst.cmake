# mvfst (QUIC) third-party integration
# Reference: https://github.com/facebook/mvfst

thirdparty_setup_directories("mvfst")

thirdparty_get_optimization_flags(_opt_flags COMPONENT mvfst)
list(APPEND _opt_flags
    -DCMAKE_INSTALL_PREFIX=${MVFST_INSTALL_DIR}

    -DCMAKE_POLICY_DEFAULT_CMP0167=OLD

    -DCMAKE_MODULE_PATH=${MVFST_SOURCE_DIR}/build/fbcode_builder/CMake

    # OpenSSL
    -DOPENSSL_ROOT_DIR=${THIRDPARTY_INSTALL_DIR}/openssl
    -DOPENSSL_INCLUDE_DIR=${THIRDPARTY_INSTALL_DIR}/openssl/include
    -DOPENSSL_SSL_LIBRARY=${THIRDPARTY_INSTALL_DIR}/openssl/lib/libssl.a
    -DOPENSSL_CRYPTO_LIBRARY=${THIRDPARTY_INSTALL_DIR}/openssl/lib/libcrypto.a

    # Sodium
    -Dsodium_DIR=${THIRDPARTY_INSTALL_DIR}/libsodium
    -Dsodium_USE_STATIC_LIBS=ON

    # jemalloc
    -DCMAKE_CXX_FLAGS=-I${THIRDPARTY_INSTALL_DIR}/jemalloc/include\ -include\ ${THIRDPARTY_INSTALL_DIR}/jemalloc/include/jemalloc_prefix_compat.h
)

# Acquire mvfst source first so we can patch files deterministically.
thirdparty_acquire_source("mvfst" _mvfst_srcdir)

# Overwrite quic/common/Expected.h in the vendor source tree before configuring/building.
# We overwrite the file with the vetted implementation to ensure consistent behavior under C++23.
file(MAKE_DIRECTORY "${_mvfst_srcdir}/quic/common")
file(WRITE "${_mvfst_srcdir}/quic/common/Expected.h" [=[
/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

/*
 * quic/common/Expected.h - wrapper aliases for quic::Expected
 */
#pragma once

#include <utility>
#include <type_traits>

// Protect against Windows macros that interfere with standard library, glog and
// QUIC code
#ifdef _WIN32
#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef GLOG_NO_ABBREVIATED_SEVERITIES
#define GLOG_NO_ABBREVIATED_SEVERITIES
#endif
// If the macros are already defined, undefine them temporarily
#ifdef max
#define QUIC_EXPECTED_HAD_MAX_MACRO
#undef max
#endif
#ifdef min
#define QUIC_EXPECTED_HAD_MIN_MACRO
#undef min
#endif
#ifdef NO_ERROR
#define QUIC_EXPECTED_HAD_NO_ERROR_MACRO
#undef NO_ERROR
#endif
#endif // _WIN32

// Forward-declare nonstd::expected_lite first, then create the compatibility
// alias *before* including the vendor header, so its hash specializations can
// resolve.
namespace nonstd {
namespace expected_lite {}
} // namespace nonstd

namespace quic {
namespace detail_expected_lite {
namespace nonstd {
namespace expected_lite = ::nonstd::expected_lite;
} // namespace nonstd
} // namespace detail_expected_lite

} // namespace quic

#include <quic/common/third-party/expected.hpp>

// Expose the vendor implementation in the global namespace symbols that
// some internal expected-lite helpers still reference.  We do this by just
// importing the wrapped namespace into the global nonstd::expected_lite name.
// This avoids touching any of the vendor code again while keeping everything
// safely under the quic namespace for ODR-safety.
// Bring vendor namespace into global nonstd as provided by vendor header.
// Already included by the header above, nothing to do.

// Legacy path mapping is now handled above before vendor header inclusion.

// Provide aliases so that legacy references like
// quic::detail_expected_lite::nonstd::expected_lite::expected<...>
// continue to compile even though the vendor code now lives in the global
// nonstd::expected_lite namespace only.
namespace quic {

// quic::Expected compatibility wrapper providing hasError()
template <class T, class E>
class Expected : public ::nonstd::expected<T, E> {
    using Base = ::nonstd::expected<T, E>;

 public:
    using Base::Base;

    constexpr bool hasError() const noexcept {
        return !Base::has_value();
    }
};

// The vendor header already provides:
//   quic::Expected            alias for
//   detail_expected_lite::nonstd::expected_lite::expected

// We only need to expose make_expected / make_unexpected helpers so that
// existing call-sites can switch from folly::make_expected/unexpected with
// a simple namespace replacement.

template <class T>
constexpr ::quic::Expected<typename std::decay<T>::type, int> make_expected(T&& value) {
    return ::quic::Expected<typename std::decay<T>::type, int>(std::forward<T>(value));
}

template <class E>
constexpr ::nonstd::unexpected_type<typename std::decay<E>::type> make_unexpected(E&& err) {
    return ::nonstd::unexpected_type<typename std::decay<E>::type>(std::forward<E>(err));
}

} // namespace quic

// Restore Windows macros if they were previously defined
#ifdef _WIN32
#ifdef QUIC_EXPECTED_HAD_MAX_MACRO
#define max(a, b) (((a) > (b)) ? (a) : (b))
#undef QUIC_EXPECTED_HAD_MAX_MACRO
#endif
#ifdef QUIC_EXPECTED_HAD_MIN_MACRO
#define min(a, b) (((a) < (b)) ? (a) : (b))
#undef QUIC_EXPECTED_HAD_MIN_MACRO
#endif
#ifdef QUIC_EXPECTED_HAD_NO_ERROR_MACRO
#define NO_ERROR 0L
#undef QUIC_EXPECTED_HAD_NO_ERROR_MACRO
#endif
#endif // _WIN32
]=])

# Configure, build and install mvfst with the patched source
thirdparty_cmake_configure("${_mvfst_srcdir}" "${MVFST_BUILD_DIR}"
    VALIDATION_FILES
        "${MVFST_BUILD_DIR}/Makefile"
        "${MVFST_BUILD_DIR}/build.ninja"
    CMAKE_ARGS
        ${_opt_flags}
)

thirdparty_cmake_install("${MVFST_BUILD_DIR}" "${MVFST_INSTALL_DIR}"
    VALIDATION_FILES
        "${MVFST_INSTALL_DIR}/lib/libmvfst_transport.a"
        "${MVFST_INSTALL_DIR}/lib/cmake/mvfst/mvfst-config.cmake"
)

halo_find_package(mvfst CONFIG QUIET REQUIRED)
