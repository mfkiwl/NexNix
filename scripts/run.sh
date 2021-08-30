#! /usr/bin/env sh
# run.sh - launches QEMU
# SPDX-License-Identifier: ISC

arch=$1
if [ -z "$arch" ]
then
    echo "$(basename $0): error: architecture must be set"
    exit 1
fi

mach=$(echo "$arch" | awk -F'-' '{ print $1 }')
board=$(echo "$arch" | awk -F'-' '{ print $2 }')

if [ "$USEBOCHS" = "1" ]
then
    # Check that the architecture can run Bochs
    if [ "$board" != "pc" ]
    then
        echo "$(basename $0): error: $arch incompatible with Bochs"
        exit 1
    fi
    if [ "$mach" = "i386" ] && [ "$USELEGACY" = "1" ]
    then
        bochs -q -f scripts/bochs-i386legacy.txt
    else
        bochs -q -f  scripts/bochs-${arch}.txt
    fi
    return
elif [ "$USEVBOX" = "1" ]
then
    # Check that the architecture can run VBox
    if [ "$board" != "pc" ]
    then
        echo "$(basename $0): error: $arch incompatible with VirtualBox"
        exit 1
    fi
    # Check if a NexNix machine has been added yet
    isnexnix=$(VBoxManage list vms | awk '/NexNix/ { print $0 }')
    rm -f images-${arch}/nndisk.vdi
    if [ ! -z "$isnexnix" ]
    then
        VBoxManage storagectl "NexNix" --name "NexNix-storage" --remove
        VBoxManage closemedium disk images-${arch}/nndisk.vdi
    fi
    VBoxManage convertfromraw images-${arch}/nndisk.img images-${arch}/nndisk.vdi --format VDI
    if [ -z "$isnexnix" ]
    then
        VBoxManage createvm --name "NexNix" --register
        VBoxManage modifyvm "NexNix" --memory 1024 --acpi on --hpet on --pae on \
                    --graphicscontroller vmsvga --usbehci on --ostype "Other_64"
    fi
    if [ "$USEBIOS" = "1" ]
    then
        VBoxManage modifyvm "NexNix" --firmware bios
    else
        VBoxManage modifyvm "NexNix" --firmware efi
    fi
    VBoxManage storagectl "NexNix" --name "NexNix-storage" --add sata --controller IntelAhci \
                    --bootable on --portcount 1
    VBoxManage storageattach "NexNix" --storagectl "NexNix-storage" --port 1 --medium \
                    "images-${arch}/nndisk.vdi" --type hdd
    # Start it
    VBoxManage startvm --putenv VBOX_GUI_DBG_ENABLED=true "NexNix"
    return
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

# Decide what disk image to use
if [ "$arch" = "i386-pc" ]
then
    if [ "$USEISO" = "1" ]
    then
        if [ "$USELEGACY" = "1" ]
        then
            disk="-cdrom images-i386-pc/nnisolegacy.iso"
        else
            disk="-cdrom images-i386-pc/nncdrom.iso"
        fi
    elif [ "$USELEGACY" = "1" ]
    then
        disk="-drive file=images-i386-pc/nnlegacy.img,format=raw"
    else
        disk="-drive file=images-i386-pc/nndisk.img,format=raw"
    fi
elif [ "$arch" = "x86_64-pc" ]
then
    if [ "$USEISO" = "1" ]
    then
        disk="-cdrom images-x86_64-pc/nncdrom.iso"
    else
        disk="-drive file=images-x86_64/nndisk.img,format=raw"
    fi
elif [ "$arch" = "aarch64-sr" ]
then
    disk="-drive file=images-aarch64-sr/nndisk.img,format=raw,id=hd0"
fi

if [ "$board" = "pc" ]
then
    if [ "$USELEGACY" = "1" ]
    then
        qemu-system-$mach -M isapc -cpu 486 -m 16M $disk
    else
        qemu-system-$mach -M q35 -m 512M -device qemu-xhci -device usb-kbd -smp 8 $disk $QEMUFLAGS
    fi
elif [ "$board" = "sr" ]
then
    qemu-system-$mach -M virt -cpu max -device qemu-xhci \
                        -device usb-kbd -device virtio-gpu -m 512M -smp 8 $QEMUFLAGS \
                        -device virtio-blk,drive=hd0 $disk
fi
