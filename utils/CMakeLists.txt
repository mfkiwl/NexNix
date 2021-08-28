# CMakeLists.txt - contains CMake stuff for host utilities
# SPDX-License-Identifier: ISC

cmake_minimum_required(VERSION 3.00 FATAL_ERROR)
project(utils VERSION 0.0.1)

add_subdirectory(mbrwrap)
add_subdirectory(confgen)
add_subdirectory(mbrwrite)
