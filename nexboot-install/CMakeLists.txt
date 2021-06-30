# CMakeLists.txt - contains build system for nexboot-install
# Distributed with NexNix, licensed under the MIT license
# See LICENSE

# Setup the basics
cmake_minimum_required(VERSION 3.16)
set(CMAKE_C_STANDARD 11)
project(nexboot-install)

# Build it
add_executable(nexboot-install nbooti.c)
install(TARGETS nexboot-install DESTINATION bin/..)
