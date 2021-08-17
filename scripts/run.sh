#! /usr/bin/env sh
# run.sh - launches QEMU
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
arch=$1
if [ -z "$arch" ]
then
    echo "$(basename $0): error: architecture must be set"
    exit 1
fi

mach=$(echo "$arch" | awk -F'-' '{ print $1 }')
board=$(echo "$arch" | awk -F'-' '{ print $2 }')

if [ "$mach" = "i686" ]
then
    mach=i386
fi

# Check if we need to use KVM
QEMUFLAGS=
if [ "$USEKVM" = "1" ]
then
    QEMUFLAGS="${QEMUFLAGS} -enable-kvm"
fi

if [ "$USEBIOS" != "1" ]
then
    QEMUFLAGS="${QEMUFLAGS} -drive if=pflash,format=raw,unit=0,file=fw/EFI_$arch.fd \
                        -drive if=pflash,format=raw,unit=1,file=fw/EFI_${arch}_VARS.fd"
fi

if [ "$board" = "pc" ]
then
    qemu-system-$mach -M q35 -m 512M -device qemu-xhci \
                        -device usb-kbd -smp 8 -drive file=images-$arch/nndisk.img,format=raw \
                        $QEMUFLAGS
elif [ "$arch" = "aarch64-sr" ]
then
    qemu-system-$mach -M virt -cpu max -device qemu-xhci -device usb-kbd -device virtio-blk,drive=hd0 \
                        -drive if=none,format=raw,file=images-$arch/nndisk.img,id=hd0 \
                        -device virtio-gpu -m 512M -smp 8 $QEMUFLAGS
fi
