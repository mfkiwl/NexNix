# CMakeLists.txt - contains main build system for NexNix
# Distributed with NexNix, licensed under the MIT license
# See LICENSE

cmake_minimum_required(VERSION 3.00)
project(NexNix VERSION 0.0.1)

# Set build flags
set(CMAKE_C_FLAGS_DEBUG ${GLOBAL_DEBUG_CFLAGS})
set(CMAKE_C_FLAGS_RELEASE ${GLOBAL_RELEASE_CFLAGS})
set(CMAKE_C_FLAGS ${GLOBAL_CFLAGS})

foreach(dir ${GLOBAL_PROJECTS})
    add_subdirectory(${dir})
endforeach()

