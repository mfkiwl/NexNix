#! /bin/bash
# buildnb.sh - script to build nexboot
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

cd fw/edk2

# Setup EDK2
. edksetup.sh > /dev/null 2>&1

EDK2ARCH=
# Convert GLOBAL_MACH to an EDK2 arch
if [ "$GLOBAL_MACH" = "i686" ]
then
    EDK2ARCH=IA32
elif [ "$GLOBAL_MACH" = "x86_64" ]
then
    EDK2ARCH=X64
elif [ "$GLOBAL_MACH" = "aarch64" ]
then
    EDK2ARCH=AARCH64
fi

# Now we run build
export GCC5_AARCH64_PREFIX=aarch64-linux-gnu-
build -a $EDK2ARCH -p MdeModulePkg/MdeModulePkg.dsc -t GCC5 -n $GLOBAL_JOBCOUNT
if [ $? -ne 0 ]
then
    echo "$0: unable to build nexboot"
    exit 1
fi

# Install it to the system root
if [ ! -d $GLOBAL_PREFIX/boot/EFI/BOOT ]
then
    mkdir -p $GLOBAL_PREFIX/boot/EFI/BOOT
fi
# Change an AArch64 EDK2ARCH to AA64
if [ "$EDK2ARCH" = "AARCH64" ]
then
    FILEARCH=AA64
else
    FILEARCH=$EDK2ARCH
fi
cp Build/MdeModule/DEBUG_GCC5/${EDK2ARCH}/nexboot.efi \
    $GLOBAL_PREFIX/boot/EFI/BOOT/BOOT${FILEARCH}.EFI
