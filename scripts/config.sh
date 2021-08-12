# config.sh - contains global build variables to be sourced into the shell
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

export GLOBAL_CMAKEVARS="-G\"Ninja\""
export GLOBAL_ACTIONS="clean image dep configure build"
GLOBAL_CMAKEVARS="${GLOBAL_CMAKEVARS} -DGLOBAL_ACTIONS=\"${GLOBAL_ACTIONS}\""

export GLOBAL_JOBCOUNT=1

export GLOBAL_DEBUG=0

export GLOBAL_PROFILE=0
GLOBAL_CMAKEVARS="${GLOBAL_CMAKEVARS} -DGLOBAL_PROFILE=\"${GLOBAL_PROFILE}\""

export GLOBAL_DEFINES=
export GLOBAL_ARCHS="x86_64-pc i686-pc aarch64-virtio aarch64-raspi3"
GLOBAL_CMAKEVARS="${GLOBAL_CMAKEVARS} -DGLOBAL_ARCHS=\"${GLOBAL_ARCHS}\""

export GLOBAL_CROSS="$PWD/cross"
GLOBAL_CMAKEVARS="${GLOBAL_CMAKEVARS} -DGLOBAL_CROSS=\"${GLOBAL_CROSS}\""

export GLOBAL_CFLAGS="-std=gnu11 -c --sysroot=$GLOBAL_PREFIX --isystem=/usr/include"
GLOBAL_CMAKEVARS="${GLOBAL_CMAKEVARS} -DGLOBAL_CFLAGS=\"${GLOBAL_CFLAGS}\""

export GLOBAL_DEBUG_CFLAGS="-g -O0"
GLOBAL_CMAKEVARS="${GLOBAL_CMAKEVARS} -DGLOBAL_DEBUG_CFLAGS=\"${GLOBAL_DEBUG_CFLAGS}\""

export GLOBAL_RELEASE_CFLAGS="-O3 -DNDEBUG"
GLOBAL_CMAKEVARS="${GLOBAL_CMAKEVARS} -DGLOBAL_RELEASE_CFLAGS=\"${GLOBAL_RELEASE_CFLAGS}\""

export GLOBAL_PROJECTS=""
GLOBAL_CMAKEVARS="${GLOBAL_CMAKEVARS} -DGLOBAL_PROJECTS=\"${GLOBAL_PROJECTS}\""

export GLOBAL_LINKFLAGS=""
GLOBAL_CMAKEVARS="${GLOBAL_CMAKEVARS} -DGLOBAL_LINKFLAGS=\"${GLOBAL_LINKFLAGS}\""
