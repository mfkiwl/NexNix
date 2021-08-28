# CMakeLists.txt - contains CMake stuff for nexboot
# SPDX-License-Identifier: ISC

cmake_minimum_required(VERSION 3.00 FATAL_ERROR)

# Build the BIOS bootloader on PC
if(${GLOBAL_BOARD} STREQUAL "pc")
    add_subdirectory(mach/bios)
endif()
