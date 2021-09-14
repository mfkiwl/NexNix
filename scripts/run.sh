#! /usr/bin/env sh
# run.sh - launches an emulator
# SPDX-License-Identifier: ISC

# TODO: allow for more flexible configuration of VMs

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
    bochs -q -f  scripts/bochs-${arch}.txt
    exit 0
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
    if [ ! -z "$isnexnix" ]
    then
        VBoxManage storagectl "NexNix" --name "NexNix-storage" --remove
        VBoxManage closemedium disk images-${arch}/nndisk.vdi

    fi
    rm -f images-${arch}/nndisk.vdi
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
                    --bootable on --portcount 2
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
    QEMUFLAGS="${QEMUFLAGS} -bios fw/OVMF-${arch}.fd"
fi

# Decide what disk image to use
if [ "$arch" = "i386-pc" ]
then
    if [ "$USEISO" = "1" ]
    then
        disk="-cdrom images-i386-pc/nncdrom.iso"
    else
        disk="-drive file=images-i386-pc/nndisk.img,format=raw"
    fi
fi

if [ "$board" = "pc" ]
then
    qemu-system-$mach -M q35 -m 512M -device qemu-xhci -device usb-kbd -smp 8 $disk $QEMUFLAGS
fi
