# CMakeLists.txt - contains CMake build stuff for neximg
# Distributed with NexNix, licensed under the MIT license
# See LICENSE

cmake_minimum_required(VERSION 3.16)
project(neximg)

# Set up flags
set(CMAKE_C_STANDARD 11)

# Set debugging flags
if(${GLOBAL_DEBUG} EQUAL 1)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O0 -g")
else()
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O3 -DNDEBUG")
endif()

# Set -pg if profiling was enabled
if(${GLOBAL_PROFILE} EQUAL 1)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -pg")
endif()

add_executable(neximg   main.c
                        disk.c)
install(TARGETS neximg DESTINATION ${CMAKE_INSTALL_PREFIX}/util)
