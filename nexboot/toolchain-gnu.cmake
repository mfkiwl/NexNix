# toolchain-gcc.cmake - sets up the toolchain for CMake
# Distributed with NexNix, licensed under the MIT license
# See LICENSE

# We now need to setup the compiler variables
set(TOOLPREFIX elf)
set(CMAKE_C_COMPILER ${CROSS}/${ARCH}-${TOOLPREFIX}-gcc)
set(CMAKE_LINKER ${CROSS}/${ARCH}-${TOOLPREFIX}-ld)
set(CMAKE_OBJCOPY ${CROSS}/${ARCH}-${TOOLPREFIX}-objcopy)
set(CMAKE_AR ${CROSS}/${ARCH}-${TOOLPREFIX}-ar)
set(CMAKE_C_COMPILER_WORKS 1)
set(CMAKE_CXX_COMPILER_WORKS 1)
