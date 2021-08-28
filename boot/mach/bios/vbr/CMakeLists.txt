# CMakeLists.txt - contains CMake stuff for nexboot VBR
# SPDX-License-Identifier: ISC

cmake_minimum_required(VERSION 3.00 FATAL_ERROR)

set(CMAKE_ASM_NASM_OBJECT_FORMAT elf32)

if(${GLOBAL_MACH} STREQUAL "x86_64")
    set(CMAKE_ASM_NASM_LINK_EXECUTABLE "${GLOBAL_CROSS}/bin/${GLOBAL_MACH}-elf-ld -Ttext=0x600 \
                        ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/nbvbr.dir/vbr.asm.o \
                        -o ${CMAKE_CURRENT_BINARY_DIR}/nbvbr --oformat=binary -e start -melf_i386")
else()
    set(CMAKE_ASM_NASM_LINK_EXECUTABLE "${GLOBAL_CROSS}/bin/${GLOBAL_MACH}-elf-ld -Ttext=0x600 \
                        ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/nbvbr.dir/vbr.asm.o \
                        -o ${CMAKE_CURRENT_BINARY_DIR}/nbvbr --oformat=binary -e start")
endif()

# Begin building the VBR
set(CMAKE_ASM_NASM_FLAGS "-DGLOBAL_DEBUG=${GLOBAL_DEBUG}")
project(nbvbr)
enable_language(ASM_NASM)

add_executable(nbvbr vbr.asm)
install(TARGETS nbvbr DESTINATION ./output)
