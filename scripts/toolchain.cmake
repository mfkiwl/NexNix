# toolchain.cmake - contains toolchain definitions
# SPDX-License-Identifier: ISC

# Set up compiler definitions
set(CMAKE_C_COMPILER ${GLOBAL_CROSS}/bin/${GLOBAL_MACH}-elf-gcc)
set(CMAKE_CXX_COMPILER ${GLOBAL_CROSS}/bin/${GLOBAL_MACH}-elf-g++)
# Setup NASM if building for PC
if(GLOBAL_BOARD STREQUAL "pc")
    find_program(CMAKE_ASM_NASM_COMPILER nasm)
    if(GLOBAL_MACH STREQUAL "i386")
        set(CMAKE_ASM_NASM_OBJECT_FORMAT elf32)
    else()
        set(CMAKE_ASM_NASM_OBJECT_FORMAT elf64)
    endif()
else()
    set(CMAKE_ASM_COMPILER ${GLOBAL_CROSS}/bin/${GLOBAL_MACH}-elf-gcc)
endif()
set(CMAKE_AR ${GLOBAL_CROSS}/bin/${GLOBAL_MACH}-elf-ar)
set(CMAKE_OBJCOPY ${GLOBAL_CROSS}/bin/${GLOBAL_MACH}-elf)
set(CMAKE_C_COMPILER_WORKS 1)
set(CMAKE_CXX_COMPILER_WORKS 1)
