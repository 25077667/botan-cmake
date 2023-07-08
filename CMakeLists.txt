cmake_minimum_required(VERSION 3.14 FATAL_ERROR)

project(botan LANGUAGES CXX)

include(FindBotan.cmake)
# Cache all results to avoid re-running FindBotan.cmake
set(BOTAN_FIND_QUIETLY TRUE CACHE BOOL "" FORCE)
set(BOTAN_FIND_REQUIRED TRUE CACHE BOOL "" FORCE)

