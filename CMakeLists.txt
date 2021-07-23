# CMakeLists.txt - contains top level build system for NexNix
# Distributed with NexNix, licensed under the MIT license
# See LICENSE

# Get this taken care of
cmake_minimum_required(VERSION 3.00 FATAL_ERROR)

# Project definition
project(NexNix VERSION 0.01)
enable_language(C ASM)

# Check for required variables
if(NOT DEFINED GLOBAL_MACHS)
    message(FATAL_ERROR "GLOBAL_MACHS must be defined!")
    return()
endif()

if(NOT DEFINED GLOBAL_ARCHS)
    message(FATAL_ERROR "GLOBAL_ARCHS must be defined!")
    return()
endif()

if(NOT DEFINED GLOBAL_PROJECTS)
    message(FATAL_ERROR "GLOBAL_PROJECTS must be defined!")
    return()
endif()

if(NOT DEFINED GLOBAL_CFLAGS)
    message(FATAL_ERROR "GLOBAL_CFLAGS must be defined!")
    return()
endif()

if(NOT DEFINED GLOBAL_MACH)
    message(FATAL_ERROR "GLOBAL_MACH must be defined!")
    return()
endif()

if(NOT DEFINED GLOBAL_BOARD)
    message(FATAL_ERROR "GLOBAL_BOARD must be defined!")
    return()
endif()

# Set the common arch
if(${GLOBAL_MACH} EQUAL "i686")
    set(GLOBAL_ARCHCOMMON "x86")
elseif(${GLOBAL_MACH} EQUAL "x86_64")
    set(GLOBAL_ARCHCOMMON "x86")
elseif(${GLOBAL_MACH} EQUAL "riscv64")
    set(GLOBAL_ARCHCOMMON "riscv")
elseif(${GLOBAL_MACH} EQUAL "aarch64")
    set(GLOBAL_ARCHCOMMON "arm")
endif()

# Add each subdirectory
foreach(dir ${GLOBAL_PROJECTS})
    add_subdirectory(${dir})
endforeach()
