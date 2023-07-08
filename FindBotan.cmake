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
)

set(BOTAN_COMFIG_ARGS "--without-documentation")

FetchContent_GetProperties(botan)
if(NOT botan_POPULATED)
    FetchContent_Populate(botan)
endif()

set(CONFIGURE_COMMAND ${Python3_EXECUTABLE} configure.py ${BOTAN_COMFIG_ARGS})
message(STATUS "Botan configure command: ${CONFIGURE_COMMAND}")
execute_process(
    COMMAND ${CONFIGURE_COMMAND}
    WORKING_DIRECTORY ${botan_SOURCE_DIR}
)

# Build Botan, only Makefile toolchain to build Botan
set(BOTAN_BUILD_COMMAND ${CMAKE_MAKE_PROGRAM})
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
   WORKING_DIRECTORY ${botan_SOURCE_DIR}
)

# Set Botan_INCLUDE_DIRS to the include directory
set(Botan_INCLUDE_DIRS ${botan_BINARY_DIR}/include PARENT_SCOPE)
# Set Botan_LIBRARIES to the library directory
set(Botan_LIBRARIES ${botan_BINARY_DIR}/lib PARENT_SCOPE)

# Set Botan_FOUND to true
set(Botan_FOUND TRUE PARENT_SCOPE)
