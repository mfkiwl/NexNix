# CMakeLists.txt - contains mbrwrite build system
# SPDX-License-Identifier: ISC

cmake_minimum_required(VERSION 3.00)
project(mbrwrite)

set(CMAKE_C_STANDARD 11)
enable_language(C)
set(CMAKE_C_FLAGS "-O3 -DNDEBUG")

add_executable(mbrwrite mbrwrite.c)
install(TARGETS mbrwrite DESTINATION .)
