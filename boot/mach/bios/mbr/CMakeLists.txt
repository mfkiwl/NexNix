# CMakeLists.txt - contains CMake stuff for nexboot MBR
# SPDX-License-Identifier: ISC

cmake_minimum_required(VERSION 3.00 FATAL_ERROR)

set(CMAKE_ASM_NASM_OBJECT_FORMAT elf32)

if(${GLOBAL_MACH} STREQUAL "x86_64")
    set(CMAKE_ASM_NASM_LINK_EXECUTABLE "${GLOBAL_CROSS}/bin/${GLOBAL_MACH}-elf-ld -Ttext=0x600 \
                        ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/nbmbr.dir/mbr.asm.o \
                        -o ${CMAKE_CURRENT_BINARY_DIR}/nbmbr --oformat=binary -e start -melf_i386")
else()
    set(CMAKE_ASM_NASM_LINK_EXECUTABLE "${GLOBAL_CROSS}/bin/${GLOBAL_MACH}-elf-ld -Ttext=0x600 \
                        ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/nbmbr.dir/mbr.asm.o \
                        -o ${CMAKE_CURRENT_BINARY_DIR}/nbmbr --oformat=binary -e start")
endif()

# Begin building the MBR
project(nbmbr)
enable_language(ASM_NASM)

add_executable(nbmbr mbr.asm)
install(TARGETS nbmbr DESTINATION ./output)
