# CMakeLists.txt - contains CMake build script for nexboot
# Distributed with NexNix, licensed under the MIT license
# See LICENSE

# Setup the basics
cmake_minimum_required(VERSION 3.16)
set(CMAKE_C_STANDARD 11)
project(nexboot VERSION 0.0.1)

# Set the common arch
if(ARCH STREQUAL "i686" OR ARCH STREQUAL "x86_64")
    set(COMMONARCH "x86")
elseif(ARCH STREQUAL "riscv32" OR ARCH STREQUAL "riscv64")
    set(COMMONARCH "riscv")
endif()

enable_language(C ASM)

# Each bootloader is completley independent of each other. Select the right one
add_subdirectory(${BOARD})
