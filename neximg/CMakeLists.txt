# CMakeLists.txt - contains CMake build stuff for neximg
# Distributed with NexNix, licensed under the MIT license
# See LICENSE

project(neximg)

# Use defaults discovered by cmake for compiler

set(CMAKE_C_FLAGS "-std=gnu11 -O3 -c")

add_executable(neximg main.c)
install(TARGETS neximg DESTINATION ${CMAKE_INSTALL_PREFIX}/util)
