# config.sh - contains global build variables to be sourced into the shell
# Distributed with NexNix, licensed under the MIT license
# See LICENSE

export GLOBAL_CMAKEVARS="-G\"Ninja\""
export GLOBAL_ACTIONS="clean image dep configure build"
GLOBAL_CMAKEVARS="${GLOBAL_CMAKEVARS} -DGLOBAL_ACTIONS=\"${GLOBAL_ACTIONS}\""

export GLOBAL_JOBCOUNT=1
GLOBAL_CMAKEVARS="${GLOBAL_CMAKEVARS} -DGLOBAL_JOBCOUNT=\"${GLOBAL_JOBCOUNT}\""

export GLOBAL_DEBUG=0
GLOBAL_CMAKEVARS="${GLOBAL_CMAKEVARS} -DGLOBAL_DEBUG=\"${GLOBAL_DEBUG}\""

export GLOBAL_PROFILE=0
GLOBAL_CMAKEVARS="${GLOBAL_CMAKEVARS} -DGLOBAL_PROFILE=\"${GLOBAL_PROFILE}\""

export GLOBAL_DEFINES=
export GLOBAL_ARCHS="x86_64-pc i686-pc riscv64-virtio aarch64-virtio aarch64-raspi3"
GLOBAL_CMAKEVARS="${GLOBAL_CMAKEVARS} -DGLOBAL_ARCHS=\"${GLOBAL_ARCHS}\""

export GLOBAL_CROSS="$PWD/cross"
GLOBAL_CMAKEVARS="${GLOBAL_CMAKEVARS} -DGLOBAL_CROSS=\"${GLOBAL_CROSS}\""

export GLOBAL_CFLAGS="-std=gnu11 -c --sysroot=$GLOBAL_PREFIX --isystem=/usr/include"
GLOBAL_CMAKEVARS="${GLOBAL_CMAKEVARS} -DGLOBAL_CFLAGS=\"${GLOBAL_CFLAGS}\""

export GLOBAL_DEBUG_CFLAGS="-g -O0"
GLOBAL_CMAKEVARS="${GLOBAL_CMAKEVARS} -DGLOBAL_DEBUG_CFLAGS=\"${GLOBAL_DEBUG_CFLAGS}\""

export GLOBAL_RELEASE_CFLAGS="-O3 -DNDEBUG"
GLOBAL_CMAKEVARS="${GLOBAL_CMAKEVARS} -DGLOBAL_RELEASE_CFLAGS=\"${GLOBAL_RELEASE_CFLAGS}\""