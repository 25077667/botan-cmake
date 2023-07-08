cmake_minimum_required(VERSION 3.14 FATAL_ERROR)

project(botan)

# Set botan variables: version, download url
set(Botan_FIND_VERSION_MAJOR 3)
set(Botan_FIND_VERSION_MINOR 0)
set(Botan_FIND_VERSION_PATCH 0)
set(Botan_VERSION_STRING ${Botan_FIND_VERSION_MAJOR}.${Botan_FIND_VERSION_MINOR}.${Botan_FIND_VERSION_PATCH})
set(DOWNLOAD_URL https://github.com/randombit/botan/archive/refs/tags/${Botan_VERSION_STRING}.tar.gz)

# Avoid warning about DOWNLOAD_EXTRACT_TIMESTAMP in CMake 3.24:
if (CMAKE_VERSION VERSION_GREATER_EQUAL "3.24.0")
    cmake_policy(SET CMP0135 NEW)
endif()

# Because Botan needs python interpreter dependencies, we need to find package Python3
find_package(Python3 COMPONENTS Interpreter REQUIRED)

# FetchContent the tarball
include(FetchContent)
FetchContent_Declare(
    botan
    URL ${DOWNLOAD_URL}
    DOWNLOAD_DIR ${CMAKE_CURRENT_BINARY_DIR}/download
    SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/source
    BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/build
    CONFIGURE_COMMAND "${Python_EXECUTABLE} ./configure.py"
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
)

# Build it as a static library
FetchContent_GetProperties(botan)
if(NOT botan_POPULATED)
    FetchContent_Populate(botan)
    add_subdirectory(${botan_SOURCE_DIR} ${botan_BINARY_DIR})
endif()

# Create a target for Botan
add_library(botan INTERFACE)
target_include_directories(botan INTERFACE ${botan_SOURCE_DIR}/include)
target_link_libraries(botan INTERFACE ${botan_BINARY_DIR}/libbotan-${Botan_VERSION_STRING}.a)

# Create a target for Botan::botan
add_library(Botan::botan ALIAS botan)
