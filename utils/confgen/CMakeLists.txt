# CMakeLists.txt - contains CMake build for confgen utility
# SPDX-License-Identifier: ISC

cmake_minimum_required(VERSION 3.00 FATAL_ERROR)
project(confgen)

set(CMAKE_C_STANDARD 11)
enable_language(C)
set(CMAKE_C_FLAGS "-O3 -DNDEBUG")

add_executable(confgen confgen.c)
install(TARGETS confgen DESTINATION .)


