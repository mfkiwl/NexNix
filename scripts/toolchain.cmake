# toolchain.cmake - contains toolchain definitions
# Distributed with NexNix, licensed under the MIT license
# See LICENSE

# Set up compiler definitions
set(CMAKE_C_COMPILER ${GLOBAL_CROSS}/bin/${GLOBAL_MACH}-elf-gcc)
set(CMAKE_CXX_COMPILER ${GLOBAL_CROSS}/bin/${GLOBAL_MACH}-elf-g++)
set(CMAKE_ASM_COMPILER ${GLOBAL_CROSS}/bin/${GLOBAL_MACH}-elf-gcc)
set(CMAKE_AR ${GLOBAL_CROSS}/bin/${GLOBAL_MACH}-elf-ar)
set(CMAKE_OBJCOPY ${GLOBAL_CROSS}/bin/${GLOBAL_MACH}-elf)
set(CMAKE_C_COMPILER_WORKS 1)
set(CMAKE_CXX_COMPILER_WORKS 1)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_C_STANDARD_LIBRARIES "-lgcc")
set(CMAKE_CXX_STANDARD_LIBRARIES "-lgcc")
