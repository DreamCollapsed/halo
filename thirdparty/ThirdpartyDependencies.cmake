# Third-party Library Dependency Management
# This file defines the dependencies between third-party libraries and provides
# functions to manage build order and dependency resolution.

# Global registry of all third-party components and their dependencies
set(THIRDPARTY_REGISTRY "" CACHE INTERNAL "Registry of all third-party components")

# Function to register a third-party component with its dependencies
function(thirdparty_register_component component_name)
    set(options)
    set(oneValueArgs VERSION URL SHA256)
    set(multiValueArgs DEPENDS_ON)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    
    # Store component information
    set(${component_name}_VERSION "${ARG_VERSION}" CACHE INTERNAL "Version of ${component_name}")
    set(${component_name}_URL "${ARG_URL}" CACHE INTERNAL "Download URL of ${component_name}")
    set(${component_name}_SHA256 "${ARG_SHA256}" CACHE INTERNAL "SHA256 hash of ${component_name}")
    set(${component_name}_DEPENDENCIES "${ARG_DEPENDS_ON}" CACHE INTERNAL "Dependencies of ${component_name}")
    
    # Add to global registry
    list(APPEND THIRDPARTY_REGISTRY "${component_name}")
    set(THIRDPARTY_REGISTRY "${THIRDPARTY_REGISTRY}" CACHE INTERNAL "Registry of all third-party components")
    
    message(STATUS "Registered component: ${component_name} (depends on: ${ARG_DEPENDS_ON})")
endfunction()

# Function to compute topological sort of components based on dependencies
function(thirdparty_compute_build_order output_var)
    set(_visited)
    set(_build_order)
    
    # Get all registered components
    set(_components ${THIRDPARTY_REGISTRY})
    
    # Recursive function to visit dependencies first
    function(_visit_component component)
        # Skip if already visited
        list(FIND _visited "${component}" _index)
        if(NOT _index EQUAL -1)
            return()
        endif()
        
        # Visit all dependencies first
        get_property(_deps CACHE "${component}_DEPENDENCIES" PROPERTY VALUE)
        if(_deps)
            foreach(_dep IN LISTS _deps)
                _visit_component("${_dep}")
            endforeach()
        endif()
        
        # Mark as visited and add to build order
        list(APPEND _visited "${component}")
        list(APPEND _build_order "${component}")
        
        # Update parent scope variables
        set(_visited "${_visited}" PARENT_SCOPE)
        set(_build_order "${_build_order}" PARENT_SCOPE)
    endfunction()
    
    # Visit all components
    foreach(_component IN LISTS _components)
        _visit_component("${_component}")
    endforeach()
    
    # Return the computed build order
    set(${output_var} "${_build_order}" PARENT_SCOPE)
endfunction()

# Function to check if all dependencies of a component are satisfied
function(thirdparty_check_dependencies component_name)
    get_property(_deps CACHE "${component_name}_DEPENDENCIES" PROPERTY VALUE)
    if(_deps)
        foreach(_dep IN LISTS _deps)
            set(_dep_install_dir "${THIRDPARTY_INSTALL_DIR}/${_dep}")
            if(NOT EXISTS "${_dep_install_dir}")
                message(FATAL_ERROR "Dependency ${_dep} required by ${component_name} is not installed at ${_dep_install_dir}")
            endif()
            message(STATUS "Dependency check passed: ${component_name} -> ${_dep} (${_dep_install_dir})")
        endforeach()
    endif()
endfunction()

# Function to get dependency paths for a component (useful for CMAKE_PREFIX_PATH)
function(thirdparty_get_dependency_paths component_name output_var)
    set(_paths)
    get_property(_deps CACHE "${component_name}_DEPENDENCIES" PROPERTY VALUE)
    if(_deps)
        foreach(_dep IN LISTS _deps)
            list(APPEND _paths "${THIRDPARTY_INSTALL_DIR}/${_dep}")
        endforeach()
    endif()
    set(${output_var} "${_paths}" PARENT_SCOPE)
endfunction()

# Function to display dependency information
function(thirdparty_show_dependencies)
    message(STATUS "=== Third-party Library Dependencies ===")
    thirdparty_compute_build_order(_build_order)
    
    message(STATUS "Build order: ${_build_order}")
    message(STATUS "")
    
    foreach(_component IN LISTS _build_order)
        get_property(_deps CACHE "${_component}_DEPENDENCIES" PROPERTY VALUE)
        get_property(_version CACHE "${_component}_VERSION" PROPERTY VALUE)
        if(_deps)
            message(STATUS "${_component} v${_version} -> depends on: ${_deps}")
        else()
            message(STATUS "${_component} v${_version} -> no dependencies")
        endif()
    endforeach()
    message(STATUS "========================================")
endfunction()

# Register all third-party components with their dependencies
# Component information (version, URL, SHA256) is loaded from ComponentsInfo.cmake
# This file only defines the dependency relationships

# Components with no dependencies
thirdparty_register_component(abseil
    VERSION "${ABSEIL_VERSION}"
    URL "${ABSEIL_URL}"
    SHA256 "${ABSEIL_SHA256}"
)

thirdparty_register_component(gtest
    VERSION "${GOOGLETEST_VERSION}"
    URL "${GOOGLETEST_URL}"
    SHA256 "${GOOGLETEST_SHA256}"
)

thirdparty_register_component(gflags
    VERSION "${GFLAGS_VERSION}"
    URL "${GFLAGS_URL}"
    SHA256 "${GFLAGS_SHA256}"
)

thirdparty_register_component(double-conversion
    VERSION "${DOUBLE_CONVERSION_VERSION}"
    URL "${DOUBLE_CONVERSION_URL}"
    SHA256 "${DOUBLE_CONVERSION_SHA256}"
)

thirdparty_register_component(fast-float
    VERSION "${FAST_FLOAT_VERSION}"
    URL "${FAST_FLOAT_URL}"
    SHA256 "${FAST_FLOAT_SHA256}"
)

thirdparty_register_component(fmt
    VERSION "${FMT_VERSION}"
    URL "${FMT_URL}"
    SHA256 "${FMT_SHA256}"
)

thirdparty_register_component(zstd
    VERSION "${ZSTD_VERSION}"
    URL "${ZSTD_URL}"
    SHA256 "${ZSTD_SHA256}"
)

thirdparty_register_component(snappy
    VERSION "${SNAPPY_VERSION}"
    URL "${SNAPPY_URL}"
    SHA256 "${SNAPPY_SHA256}"
)

thirdparty_register_component(openssl
    VERSION "${OPENSSL_VERSION}"
    URL "${OPENSSL_URL}"
    SHA256 "${OPENSSL_SHA256}"
)

thirdparty_register_component(lz4
    VERSION "${LZ4_VERSION}"
    URL "${LZ4_URL}"
    SHA256 "${LZ4_SHA256}"
    DEPENDS_ON zstd
)

# Components with dependencies
thirdparty_register_component(glog
    VERSION "${GLOG_VERSION}"
    URL "${GLOG_URL}"
    SHA256 "${GLOG_SHA256}"
    DEPENDS_ON gflags gtest
)

# Register jemalloc component
thirdparty_register_component(jemalloc
    URL "${JEMALLOC_URL}"
    SHA256 "${JEMALLOC_SHA256}"
    # jemalloc has no dependencies
)
