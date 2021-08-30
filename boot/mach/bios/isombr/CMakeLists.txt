# CMakeLists.txt - builds the ISO bootloader
# Distributed with NexNix, licensed under the MIT license
# See LICENSE

cmake_minimum_required(VERSION 3.00 FATAL_ERROR)

set(CMAKE_ASM_NASM_OBJECT_FORMAT elf32)

if(${GLOBAL_MACH} STREQUAL "x86_64")
    set(CMAKE_ASM_NASM_LINK_EXECUTABLE "${GLOBAL_CROSS}/bin/${GLOBAL_MACH}-elf-ld -Ttext=0x600 \
                        ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/nbisombr.dir/isombr.asm.o \
                        -o ${CMAKE_CURRENT_BINARY_DIR}/nbisombr --oformat=binary -e start -melf_i386")
else()
    set(CMAKE_ASM_NASM_LINK_EXECUTABLE "${GLOBAL_CROSS}/bin/${GLOBAL_MACH}-elf-ld -Ttext=0x600 \
                        ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/nbisombr.dir/isombr.asm.o \
                        -o ${CMAKE_CURRENT_BINARY_DIR}/nbisombr --oformat=binary -e start")
endif()

project(nbisombr)
enable_language(ASM_NASM)

add_executable(nbisombr isombr.asm)
install(TARGETS nbisombr DESTINATION ./output)
