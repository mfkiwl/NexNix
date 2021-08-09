#! /usr/bin/env sh
# run.sh - launches QEMU
# Distributed with NexNix, licensed under the MIT license
# See LICENSE

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

if [ "$board" = "pc" ]
then
    qemu-system-$mach -M q35 -m 512M -drive if=pflash,format=raw,unit=0,file=fw/EFI_$arch.fd \
                        -drive if=pflash,format=raw,unit=1,file=fw/EFI_${arch}_VARS.fd \
                        -device qemu-xhci -device usb-kbd -smp 8 -drive file=images-$arch/nndisk.img,format=raw
elif [ "$arch" = "aarch64-virtio" ]
then
    qemu-system-$mach -M virt -cpu max -drive if=pflash,format=raw,unit=0,file=fw/EFI_$arch.fd \
                        -drive if=pflash,format=raw,unit=1,file=fw/EFI_${arch}_VARS.fd -device qemu-xhci \
                        -device usb-kbd -device virtio-blk,drive=hd0 \
                        -drive if=none,format=raw,file=images-$arch/nndisk.img,id=hd0 \
                        -device virtio-gpu -m 512M -smp 8
fi