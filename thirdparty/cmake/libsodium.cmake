# libsodium third-party integration
# Reference: https://github.com/jedisct1/libsodium
# libsodium is a modern, easy-to-use software library for encryption, decryption, 
# signatures, password hashing and more.

set(_libsodium_extra_args)

# Function: halo_libsodium_post_install_merge
# Purpose: Some builds place AEGIS armcrypto implementations only inside a libtool
# convenience archive (libarmcrypto.a) that libtool may not fully fold into the
# installed static archive libsodium.a on macOS ARM with certain optimization /
# visibility combinations. This leads to undefined references to
# _aegis128l_armcrypto_implementation and _aegis256_armcrypto_implementation.
# We detect absence of those symbols post-install and, if the build-tree
# convenience archive exists, we re-archive its relevant object files into the
# installed libsodium.a. This is intentionally conservative and idempotent.
function(halo_libsodium_post_install_merge)
    if(NOT APPLE OR NOT CMAKE_SYSTEM_PROCESSOR MATCHES "[Aa][Rr][Mm]64|aarch64")
        return()
    endif()
    if(NOT DEFINED LIBSODIUM_INSTALL_DIR)
        message(DEBUG "[libsodium] Install dir variable not defined; skip merge")
        return()
    endif()
    set(_install_archive "${LIBSODIUM_INSTALL_DIR}/lib/libsodium.a")
    if(NOT EXISTS "${_install_archive}")
        message(DEBUG "[libsodium] Installed archive not found; skip merge")
        return()
    endif()
    if(NOT DEFINED THIRDPARTY_BUILD_DIR)
        message(DEBUG "[libsodium] THIRDPARTY_BUILD_DIR not defined; skip merge")
        return()
    endif()
    # Quick symbol presence check
    if(CMAKE_NM)
        execute_process(COMMAND ${CMAKE_NM} -gU ${_install_archive}
            OUTPUT_VARIABLE _nm_scan ERROR_QUIET)
        string(FIND "${_nm_scan}" "_aegis128l_armcrypto_implementation" _has128)
        string(FIND "${_nm_scan}" "_aegis256_armcrypto_implementation" _has256)
        if(_has128 GREATER -1 AND _has256 GREATER -1)
            message(DEBUG "[libsodium] Armcrypto AEGIS symbols already present; merge not needed")
            return()
        endif()
    endif()
    set(_build_armcrypto "${THIRDPARTY_BUILD_DIR}/libsodium/src/libsodium/.libs/libarmcrypto.a")
    if(NOT EXISTS "${_build_armcrypto}")
        message(DEBUG "[libsodium] Convenience archive libarmcrypto.a not found; cannot merge")
        return()
    endif()
    set(_merge_dir "${CMAKE_BINARY_DIR}/libsodium_armcrypto_merge")
    file(REMOVE_RECURSE "${_merge_dir}")
    file(MAKE_DIRECTORY "${_merge_dir}")
    # Copy current installed archive into merge dir
    file(COPY "${_install_archive}" DESTINATION "${_merge_dir}")
    get_filename_component(_install_archive_name "${_install_archive}" NAME)
    # Extract objects from convenience archive
    execute_process(COMMAND ar -x "${_build_armcrypto}" WORKING_DIRECTORY "${_merge_dir}" RESULT_VARIABLE _ar_extract)
    if(NOT _ar_extract EQUAL 0)
        message(WARNING "[libsodium] Failed to extract libarmcrypto.a objects (ar exit=${_ar_extract}); skipping merge")
        return()
    endif()
    file(GLOB _armcrypto_objs "${_merge_dir}/*aegis*armcrypto*.o" "${_merge_dir}/*aead_aes256gcm_armcrypto*.o")
    if(NOT _armcrypto_objs)
        message(WARNING "[libsodium] No armcrypto objects found after extraction; skip merge")
        return()
    endif()
    # Append objects into archive (idempotent even if repeated; duplicates replaced).
    execute_process(COMMAND ar rcs "${_merge_dir}/${_install_archive_name}" ${_armcrypto_objs} RESULT_VARIABLE _ar_add)
    if(NOT _ar_add EQUAL 0)
        message(WARNING "[libsodium] Failed to append armcrypto objects (ar exit=${_ar_add}); skipping merge")
        return()
    endif()
    execute_process(COMMAND ranlib "${_merge_dir}/${_install_archive_name}" RESULT_VARIABLE _ranlib_res)
    if(NOT _ranlib_res EQUAL 0)
        message(WARNING "[libsodium] ranlib failed (exit=${_ranlib_res}); archive may be inconsistent")
        return()
    endif()
    # Replace installed archive
    file(COPY "${_merge_dir}/${_install_archive_name}" DESTINATION "${LIBSODIUM_INSTALL_DIR}/lib")
    message(STATUS "[libsodium] Merged armcrypto objects into installed libsodium.a")
endfunction()
# Strengthen feature detection & codegen for AEGIS armcrypto implementations.
# Prior logic overwrote CFLAGS with a bare -march= flag (dropping optimization and LTO flags),
# which could yield inconsistent compilation (aead_aegis* compiled with HAVE_ARMCRYPTO while
# aegis*_armcrypto.c sources were skipped) causing undefined symbols at link time.
if(APPLE AND CMAKE_SYSTEM_PROCESSOR MATCHES "[Aa][Rr][Mm]64|aarch64")
    # Start from current project C flags so we don't lose -O3, -flto, warning, or sanitizer options.
    set(_libsodium_base_cflags "${CMAKE_C_FLAGS}")

    # If there is no explicit -march armv8 spec, append one with crypto & aes extensions.
    if(NOT _libsodium_base_cflags MATCHES "-march=.*armv8")
        string(APPEND _libsodium_base_cflags " -march=armv8-a+crypto+aes")
    else()
        # Ensure +crypto+aes are present: easiest portable approach is to append a second -march
        # (later flag generally wins). Avoid regex surgery on existing flag complexity.
        if(NOT _libsodium_base_cflags MATCHES "+crypto" OR NOT _libsodium_base_cflags MATCHES "+aes")
            string(APPEND _libsodium_base_cflags " -march=armv8-a+crypto+aes")
        endif()
    endif()

    # Allow opting out of disabling LTO for libsodium; default off because ThinLTO occasionally
    # dropped armcrypto objects before indirect dispatch referenced them, producing undefined symbols.
    if(NOT DEFINED HALO_LIBSODIUM_ENABLE_LTO)
        set(HALO_LIBSODIUM_ENABLE_LTO OFF)
    endif()
    if(NOT HALO_LIBSODIUM_ENABLE_LTO)
        if(_libsodium_base_cflags MATCHES "-flto")
            # Do not attempt complex removal; just append -fno-lto which overrides earlier -flto for clang.
            string(APPEND _libsodium_base_cflags " -fno-lto")
        else()
            string(APPEND _libsodium_base_cflags " -fno-lto")
        endif()
    endif()

    # Collapse whitespace
    string(REGEX REPLACE "[ \t]+" " " _libsodium_base_cflags "${_libsodium_base_cflags}")
    string(STRIP "${_libsodium_base_cflags}" _libsodium_base_cflags)
    list(APPEND _libsodium_extra_args CFLAGS=${_libsodium_base_cflags})
    message(STATUS "[libsodium] Using augmented CFLAGS for armcrypto detection: '${_libsodium_base_cflags}' (HALO_LIBSODIUM_ENABLE_LTO=${HALO_LIBSODIUM_ENABLE_LTO})")
endif()

thirdparty_build_autotools_library("libsodium"
    CONFIGURE_ARGS
        --enable-static
        --disable-shared
        # Drop --enable-minimal to retain AEGIS armcrypto objects (it prunes too aggressively for our requirements)
        --disable-debug
        --disable-dependency-tracking
        --with-pic
        --enable-aead
        ${_libsodium_extra_args}
    POST_INSTALL_COMMAND halo_libsodium_post_install_merge
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/libsodium/lib/libsodium.a"
        "${THIRDPARTY_INSTALL_DIR}/libsodium/include/sodium.h"
        "${THIRDPARTY_INSTALL_DIR}/libsodium/lib/pkgconfig/libsodium.pc"
)

if(EXISTS "${LIBSODIUM_INSTALL_DIR}/lib/libsodium.a")
    if(NOT TARGET libsodium::libsodium)
        add_library(libsodium::libsodium STATIC IMPORTED)
        set_target_properties(libsodium::libsodium PROPERTIES
            IMPORTED_LOCATION "${LIBSODIUM_INSTALL_DIR}/lib/libsodium.a"
            INTERFACE_INCLUDE_DIRECTORIES "${LIBSODIUM_INSTALL_DIR}/include"
        )
        halo_find_package(Threads)
        if(Threads_FOUND)
            set_target_properties(libsodium::libsodium PROPERTIES
                INTERFACE_LINK_LIBRARIES "Threads::Threads"
            )
        endif()
        # On macOS with ThinLTO and static linking, certain libsodium AEGIS armcrypto
        # implementation symbols can be dead-stripped before they are referenced via
        # function-pointer selection (runtime dispatch). Force the linker to retain
        # them similarly to how we pin libunwind symbols elsewhere.
        if(APPLE AND CMAKE_SYSTEM_PROCESSOR MATCHES "[Aa][Rr][Mm]64|aarch64")
            # --- Force load convenience lib to ensure armcrypto implementation symbols are pulled in (方案A) ---
            # We reference the build-tree convenience archive directly. This unblocks linking even though
            # the installed libsodium.a does not contain the armcrypto data symbols.
            set(_libsodium_armcrypto_archive "${THIRDPARTY_BUILD_DIR}/libsodium/src/libsodium/.libs/libarmcrypto.a")
            if(EXISTS "${_libsodium_armcrypto_archive}")
                get_target_property(_sodium_link_opts_force libsodium::libsodium INTERFACE_LINK_OPTIONS)
                if(NOT _sodium_link_opts_force)
                    set(_sodium_link_opts_force "")
                endif()
                list(APPEND _sodium_link_opts_force "-Wl,-force_load,${_libsodium_armcrypto_archive}")
                set_target_properties(libsodium::libsodium PROPERTIES INTERFACE_LINK_OPTIONS "${_sodium_link_opts_force}")
                message(STATUS "[libsodium] Added -force_load for armcrypto convenience archive (方案A)")
            else()
                message(WARNING "[libsodium] armcrypto convenience archive not found; cannot apply -force_load workaround")
            endif()
            # Only force retention if the symbols actually exist in the archive.
            # Some build variants (e.g., configured without detected armcrypto) won't produce them.
            execute_process(
                COMMAND ${CMAKE_NM} -gU ${LIBSODIUM_INSTALL_DIR}/lib/libsodium.a
                OUTPUT_VARIABLE _sodium_nm_out
                ERROR_QUIET
            )
            string(FIND "${_sodium_nm_out}" "_aegis128l_armcrypto_implementation" _has_aegis128l)
            string(FIND "${_sodium_nm_out}" "_aegis256_armcrypto_implementation" _has_aegis256)
            if((_has_aegis128l GREATER -1) AND (_has_aegis256 GREATER -1))
                get_target_property(_sodium_link_opts libsodium::libsodium INTERFACE_LINK_OPTIONS)
                if(NOT _sodium_link_opts)
                    set(_sodium_link_opts "")
                endif()
                list(APPEND _sodium_link_opts "-Wl,-u,_aegis128l_armcrypto_implementation" "-Wl,-u,_aegis256_armcrypto_implementation")
                set_target_properties(libsodium::libsodium PROPERTIES INTERFACE_LINK_OPTIONS "${_sodium_link_opts}")
                message(DEBUG "[libsodium] Forcing retention of AEGIS armcrypto symbols on macOS arm64")
            else()
                # Fallback: armcrypto implementation symbols not present in installed archive.
                # We already add -force_load for the build-tree convenience archive earlier when it exists.
                # No extra project option is exposed; just emit a debug note.
                message(DEBUG "[libsodium] AEGIS armcrypto symbols absent from installed libsodium.a; relying on earlier -force_load (if available); skipping -Wl,-u force retention")
            endif()
        endif()
        message(DEBUG "Created libsodium::libsodium target")
    endif()
else()
    message(FATAL_ERROR "libsodium installation not found at ${LIBSODIUM_INSTALL_DIR}")
endif()
