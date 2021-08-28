# CMakeLists.txt - contains CMake stuff for nexboot
# SPDX-License-Identifier: ISC

cmake_minimum_required(VERSION 3.00 FATAL_ERROR)
project(nexboot)

enable_language(C ASM_NASM)

set(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS)

set(CMAKE_C_FLAGS "${GLOBAL_CFLAGS} ${NEXBOOT_BIOS_CFLAGS}")
set(CMAKE_EXE_LINKER_FLAGS "-T${CMAKE_CURRENT_SOURCE_DIR}/arch/i386/link.ld ${NEXBOOT_BIOS_LDFLAGS}")

add_executable(nexboot start.asm
                        main.c)

target_link_libraries(nexboot "${NEXBOOT_LINKLIBS}")

install(TARGETS nexboot DESTINATION ./output)
