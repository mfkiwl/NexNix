# CMakeLists.txt - contains CMake build script for BIOS PC systems
# Distributed with NexNix, licensed under the MIT license
# See LICENSE

# Setup the basics
cmake_minimum_required(VERSION 3.16)
set(CMAKE_C_STANDARD 11)
# Build the MBR first
project(mbr)

set(CMAKE_C_FLAGS "")
set(CMAKE_EXE_LINKER_FLAGS "-Ttext=0x600 -Wl,--oformat=binary -nostdlib -fno-pie")

add_executable(mbr boot/mbr.s)
install(TARGETS mbr DESTINATION usr/bin/../../boot)
