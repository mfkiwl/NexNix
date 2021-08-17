# CMakeLists.txt - contains CMake stuff for nexboot BIOS
# Copyright 2021 Jedidiah Thompson
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

cmake_minimum_required(VERSION 3.00 FATAL_ERROR)

# Begin building the MBR
project(nbmbr)
enable_language(ASM_NASM)

# Setup the flags for NASM
set(OLD_ASMFLAGS ${CMAKE_ASM_FLAGS})
# CMake's NASM support is very broken. This kind of fixes it
set(CMAKE_ASM_NASM_LINK_EXECUTABLE "${GLOBAL_CROSS}/bin/${GLOBAL_MACH}-elf-ld -Ttext=0x600 \
${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/nbmbr.dir/start/mbr.asm.o -o ${CMAKE_CURRENT_BINARY_DIR}/nbmbr \
--oformat=binary")
set(CMAKE_ASM_FLAGS "-felf32")

add_executable(nbmbr start/mbr.asm)
install(TARGETS nbmbr DESTINATION ./biosboot)
