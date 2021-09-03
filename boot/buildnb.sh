#! /bin/bash
# buildnb.sh - script to build nexboot
# SPDX-License-Identifier: ISC

cd fw/edk2

# Setup EDK2
. edksetup.sh > /dev/null 2>&1

EDK2ARCH=
# Convert GLOBAL_MACH to an EDK2 arch
if [ "$GLOBAL_MACH" = "i386" ]
then
    EDK2ARCH=IA32
fi

# Now we run build
build -a $EDK2ARCH -p MdeModulePkg/MdeModulePkg.dsc -t GCC5 -n $GLOBAL_JOBCOUNT
if [ $? -ne 0 ]
then
    echo "$0: unable to build nexboot"
    exit 1
fi

# Install it to the system root
if [ ! -d $GLOBAL_PREFIX/output ]
then
    mkdir -p $GLOBAL_PREFIX/output
fi
cp Build/MdeModule/DEBUG_GCC5/${EDK2ARCH}/nexboot.efi \
    $GLOBAL_PREFIX/output/BOOT${EDK2ARCH}.EFI
