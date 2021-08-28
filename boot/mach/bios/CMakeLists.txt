# CMakeLists.txt - contains CMake stuff for nexboot BIOS
# SPDX-License-Identifier: ISC

cmake_minimum_required(VERSION 3.00 FATAL_ERROR)

add_subdirectory(mbr)
add_subdirectory(vbr)
add_subdirectory(nexboot)
