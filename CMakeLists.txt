# CMakeLists.txt - contains main build system for NexNix
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

cmake_minimum_required(VERSION 3.00)
project(NexNix VERSION 0.0.1)

# Set build flags
set(CMAKE_C_FLAGS_DEBUG ${GLOBAL_DEBUG_CFLAGS})
set(CMAKE_C_FLAGS_RELEASE ${GLOBAL_RELEASE_CFLAGS})
set(CMAKE_C_FLAGS ${GLOBAL_CFLAGS})

foreach(dir ${GLOBAL_PROJECTS})
    add_subdirectory(${dir})
endforeach()

