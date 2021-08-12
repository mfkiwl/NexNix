# toolchain.cmake - contains toolchain definitions
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
