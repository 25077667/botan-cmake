cmake_minimum_required(VERSION 3.14 FATAL_ERROR)
project(botan)

# Set botan variables: version, download url
set(Botan_FIND_VERSION_MAJOR 3)
set(Botan_FIND_VERSION_MINOR 1)
set(Botan_FIND_VERSION_PATCH 1)
set(Botan_VERSION_STRING ${Botan_FIND_VERSION_MAJOR}.${Botan_FIND_VERSION_MINOR}.${Botan_FIND_VERSION_PATCH})
set(DOWNLOAD_URL https://github.com/randombit/botan/archive/refs/tags/${Botan_VERSION_STRING}.tar.gz)

# Avoid warning about DOWNLOAD_EXTRACT_TIMESTAMP in CMake 3.24:
if (CMAKE_VERSION VERSION_GREATER_EQUAL "3.24.0")
    cmake_policy(SET CMP0135 NEW)
endif()

# Function to find Python3 interpreter
function(find_python3)
    find_package(Python3 COMPONENTS Interpreter REQUIRED)

    # Expose the Python3_EXECUTABLE to the parent scope
    set(Python3_EXECUTABLE ${Python3_EXECUTABLE} PARENT_SCOPE)
endfunction()

# Function to fetch the tarball
function(fetch_tarball)
    include(FetchContent)
    FetchContent_Declare(botan URL ${DOWNLOAD_URL})
    FetchContent_GetProperties(botan)
    if(NOT botan_POPULATED)
        FetchContent_Populate(botan)
    endif()
endfunction()

# Function to set the CXX compiler for configure.py
function(set_cxx_compiler)
    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        set(BOTAN_CXX_COMPILER "gcc")
    elseif (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        set(BOTAN_CXX_COMPILER "clang")
    elseif (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")  
        set(BOTAN_CXX_COMPILER "msvc")
    elseif (CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
        set(BOTAN_CXX_COMPILER "clang")
    endif()

    # Expose the CXX compiler to configure.py
    set(BOTAN_CXX_COMPILER ${BOTAN_CXX_COMPILER} PARENT_SCOPE)
endfunction()

# Function to rename Makefile if it exists
function(rename_makefile_if_exists source_dir)
    if (EXISTS ${source_dir}/Makefile)
        file(RENAME ${source_dir}/Makefile ${source_dir}/Makefile.old)
    endif()
endfunction()

# Function to generate Makefile using configure.py
function(generate_makefile source_dir)
    set(BOTAN_CONFIG_ARGS 
        --cc=${BOTAN_CXX_COMPILER}
        --without-documentation
        --build-targets=static
    )
    set(CONFIGURE_COMMAND ${Python3_EXECUTABLE} configure.py ${BOTAN_CONFIG_ARGS})
    message(STATUS "Botan configure command: ${CONFIGURE_COMMAND}")
    execute_process(
        COMMAND ${CONFIGURE_COMMAND}
        WORKING_DIRECTORY ${source_dir}
    )
endfunction()

# Function to check if Makefile needs to be rebuilt
function(check_makefile_rebuild source_dir)
    if (EXISTS ${source_dir}/Makefile.old)
        # If it is Windows, we use cmd.exe to fc Makefile and Makefile.old
        # because diff command is not available in Windows
        if (WIN32)
            set(DIFF_COMMAND cmd.exe /c "fc ${source_dir}/Makefile ${source_dir}/Makefile.old")
        else()
            set(DIFF_COMMAND diff ${source_dir}/Makefile ${source_dir}/Makefile.old)
        endif()

        execute_process(
            COMMAND ${DIFF_COMMAND}
            RESULT_VARIABLE DIFF_RESULT
        )
        set (DIFF_RESULT ${DIFF_RESULT} PARENT_SCOPE)
    endif()
endfunction()

# Function to build Botan using Makefile
function(build_botan source_dir)
    set(BOTAN_BUILD_COMMAND make)
    # Enable parallel build and color output
    if(NOT DEFINED PROCESSOR_COUNT)
        include(ProcessorCount)
        ProcessorCount(PROCESSOR_COUNT)
        if(NOT PROCESSOR_COUNT EQUAL 0)
            set(PROCESSOR_COUNT 4)
        endif()
    endif()

    set(BOTAN_BUILD_COMMAND ${BOTAN_BUILD_COMMAND} -j ${PROCESSOR_COUNT})
    execute_process(
        COMMAND ${BOTAN_BUILD_COMMAND}
        WORKING_DIRECTORY ${source_dir}
    )
endfunction()

# Main script

# Find Python3 interpreter
find_python3()

# Fetch the tarball
fetch_tarball()

# Set the CXX compiler for configure.py
set_cxx_compiler()

# Set botan_SOURCE_DIR to _deps/botan-src/
set(botan_SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/../botan-src)

# Rename Makefile if it exists
rename_makefile_if_exists(${botan_SOURCE_DIR})

# Generate Makefile using configure.py
generate_makefile(${botan_SOURCE_DIR})

# Check if Makefile needs to be rebuilt
check_makefile_rebuild(${botan_SOURCE_DIR})

if (NOT DIFF_RESULT EQUAL 0)
    # Build Botan using Makefile
    build_botan(${botan_SOURCE_DIR})
else()
    message(STATUS "Botan is already built")
endif()
