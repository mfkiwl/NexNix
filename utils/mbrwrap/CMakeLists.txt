# CMakeLists.txt - contains CMake build for mbrwrap utility
# Distributed with NexNix, licensed under the MIT license
# See LICENSE

cmake_minimum_required(VERSION 3.00 FATAL_ERROR)
project(mbrwrap VERSION 0.0.1)
enable_language(C)

add_executable(mbrwrap mbrwrap.c)
install(TARGETS mbrwrap DESTINATION .)
