#! /usr/bin/env sh
# builddep.sh - builds dependencies of build process
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

# Versions
gmpver=6.2.1
mpfrver=4.1.0
mpcver=1.2.1
binutilsver=2.37
gccver=11.1.0

testpassed=1

# Prints out an error
error()
{
    echo "$(basename $0): error: $1" >&2
}

# Prints an error and exits
panic()
{
    echo "$(basename $0): error: $1" >&2
    exit 1
}

# Prints out a message
message()
{
    echo "$0: $1"
}

# Checks if an error occured, and panics if one did
checkerr()
{
    if [ "$1" != "0" ]
    then
        panic "$2"
    fi
}

# Prints a dependency list
printdep()
{
    echo "In order to build NexNix, the following is required:"
    echo "A nearly POSIX compliant shell, bash (for building the toolchain), \
GNU make (for building the toolchain), perl, texinfo, system build utilites (gcc, make, etc) \
cmake, tar, flex, bison, gettext, wget, kpartx, mkfs.ext2, git, \
aarch64 GCC, GNU parted, acpica-tools, nasm, DD, python3, and the ninja build system"
}

# Checks one individual dependency
checkdep()
{
    if ! command -v $1 > /dev/null
    then
        error "$1 could not be found"
        testpassed=0
    else
        if [ $testpassed -ne 0 ]
        then
            testpassed=1
        fi
    fi
}

# Checks for build dependencies
builddep()
{
    echo -n "Checking for dependencies..."
    checkdep bash
    checkdep gmake
    checkdep gcc
    checkdep tar
    checkdep info
    checkdep perl
    checkdep gettext
    checkdep bison
    checkdep flex
    checkdep cmake
    checkdep wget
    checkdep ninja
    checkdep kpartx
    checkdep mkfs.ext2
    checkdep parted
    checkdep git
    checkdep aarch64-linux-gnu-gcc
    checkdep iasl
    checkdep python
    checkdep nasm
    checkdep dd

    if [ $testpassed -eq 0 ]
    then
        printdep
        exit 1
    fi
    echo "ok"
}

builddeplib()
{
    # Build libgmp
    echo -n "Downloading libgmp..."
    wget https://ftp.gnu.org/gnu/gmp/gmp-$gmpver.tar.xz > build.log 2> builderr.log
    checkerr $? "libgmp download failed"
    echo "ok"
    echo -n "Extracting libgmp..."
    tar xf gmp-$gmpver.tar.xz
    checkerr $? "libgmp extraction failed"
    echo "ok"
    echo -n "Building libgmp..."
    mkdir gmp-build
    cd gmp-build
    ../gmp-$gmpver/configure --disable-shared --prefix=$PWD/../../deplib > build.log 2> builderr.log
    checkerr $? "libgmp configure failed"
    make -j$GLOBAL_JOBCOUNT > build.log 2> builderr.log
    checkerr $? "libgmp build failed"
    make check -j$GLOBAL_JOBCOUNT > build.log 2> builderr.log
    checkerr $? "libgmp test failed"
    echo "ok"
    echo -n "Installing libgmp..."
    make install -j$GLOBAL_JOBCOUNT > build.log 2> builderr.log
    checkerr $? "libgmp install failed"
    echo "ok"

    # Build libmpfr
    echo -n "Downloading libmpfr..."
    cd ..
    wget https://ftp.gnu.org/gnu/mpfr/mpfr-$mpfrver.tar.gz > build.log 2> builderr.log
    checkerr $? "libmpfr download failed"
    echo "ok"
    echo -n "Extracting libmpfr..."
    tar xf mpfr-$mpfrver.tar.gz
    checkerr $? "libmpfr extraction failed"
    echo "ok"
    echo -n "Building libmpfr..."
    mkdir mpfr-build
    cd mpfr-build
    ../mpfr-$mpfrver/configure --disable-shared --prefix=$PWD/../../deplib \
                    --with-gmp=$PWD/../../deplib > build.log 2> builderr.log
    checkerr $? "libmpfr configure failed"
    make -j$GLOBAL_JOBCOUNT > build.log 2> builderr.log
    checkerr $? "libmpfr build failed"
    echo "ok"
    echo -n "Installing libmpfr..."
    make install -j$GLOBAL_JOBCOUNT > build.log 2> builderr.log
    checkerr $? "libmpfr install failed"
    echo "ok"

    # Build libmpc
    echo -n "Downloading libmpc..."
    cd ..
    wget https://ftp.gnu.org/gnu/mpc/mpc-$mpcver.tar.gz > build.log 2> builderr.log
    checkerr $? "libmpc download failed"
    echo "ok"
    echo -n "Extracting libmpc..."
    tar xf mpc-$mpcver.tar.gz
    checkerr $? "libmpc extraction failed"
    echo "ok"
    echo -n "Building libmpc..."
    mkdir mpc-build
    cd mpc-build
    ../mpc-$mpcver/configure --disable-shared --prefix=$PWD/../../deplib \
                    --with-gmp=$PWD/../../deplib --with-mpfr=$PWD/../../deplib \
                    > build.log 2> builderr.log
    checkerr $? "libmpc configure failed"
    make -j$GLOBAL_JOBCOUNT > build.log 2> builderr.log
    checkerr $? "libmpc build failed"
    echo "ok"
    echo -n "Installing libmpc..."
    make install -j$GLOBAL_JOBCOUNT > build.log 2> builderr.log
    checkerr $? "libmpc install failed"
    echo "ok"
}

buildbinutils()
{
    cd $GLOBAL_CROSS/src
    # Check if binutils needs to be built
    if [ -f "$GLOBAL_CROSS/bin/$GLOBAL_MACH-elf-ld" ] && [ "$REBUILD" != "1" ]
    then
        return
    fi

    # Remove any previous binutils source
    rm -rf binutils-build
    rm -rf binutils-$binutilsver
    rm -f binutils-$binutilsver.tar.gz

    echo -n "Downloading binutils..."
    wget https://ftp.gnu.org/gnu/binutils/binutils-$binutilsver.tar.gz > build.log 2> builderr.log
    checkerr $? "binutils download failed"
    echo "ok"
    echo -n "Extracting binutils..."
    tar xf binutils-$binutilsver.tar.gz
    checkerr $? "binutils extraction failed"
    echo "ok"
    echo -n "Building binutils..."
    mkdir binutils-build
    cd binutils-build
    ../binutils-$binutilsver/configure --prefix=$PWD/../.. --target=$GLOBAL_MACH-elf \
                            --disable-nls --disable-werror --enable-sysroot > /dev/null \
                            2> /dev/null
    checkerr $? "binutils configure failed"
    gmake -j$GLOBAL_JOBCOUNT > build.log 2> builderr.log
    checkerr $? "binutils build failed"
    echo "ok"
    echo -n "Installing binutils..."
    gmake install -j$GLOBAL_JOBCOUNT > build.log 2> builderr.log
    checkerr $? "binutils install failed"
    echo "ok"
}

# Builds GCC
buildgcc()
{
    cd $GLOBAL_CROSS/src

    # Check if binutils needs to be built
    if [ -f "$GLOBAL_CROSS/bin/$GLOBAL_MACH-elf-gcc" ] && [ "$REBUILD" != "1" ]
    then
        return
    fi

    # Remove any previous binutils source
    rm -rf build-gcc
    rm -rf gcc-$gccver
    rm -f gcc-$gccver.tar.gz

    # Download and extract GCC
    echo -n "Downloading GCC..."
    wget https://ftp.gnu.org/gnu/gcc/gcc-$gccver/gcc-$gccver.tar.gz > build.log 2> builderr.log
    checkerr $? "GCC download failed"
    echo "ok"

    echo -n "Extracting GCC..."
    tar xf gcc-$gccver.tar.gz
    checkerr $? "GCC extraction failed"
    echo "ok"

    # Patch GCC for red zone
    echo -n "Patching GCC..."
    patch -p0 < $PWD/../../dep/gcc.patch > build.log 2> builderr.log
    checkerr $? "GCC patching failed"
    echo "ok"

    # Build it
    echo -n "Building GCC..."
    mkdir build-gcc && cd build-gcc
    ../gcc-$gccver/configure --prefix=$PWD/../.. --target=$GLOBAL_MACH-elf --enable-languages=c,c++ \
                                --disable-nls --without-headers --with-gmp=$PWD/../../deplib \
                                --with-mpfr=$PWD/../../deplib --with-mpc=$PWD/../../deplib \
                                > build.log 2> builderr.log
    checkerr $? "GCC configure failed"
    gmake all-gcc -j$GLOBAL_JOBCOUNT > build.log 2> builderr.log
    checkerr $? "GCC build failed"
    gmake all-target-libgcc -j$GLOBAL_JOBCOUNT > build.log 2> builderr.log
    checkerr $? "GCC build failed"
    echo "ok"
    echo -n "Installing GCC..."
    gmake install-gcc -j$GLOBAL_JOBCOUNT > build.log 2> builderr.log
    checkerr $? "GCC install failed"
    gmake install-target-libgcc -j$GLOBAL_JOBCOUNT > build.log 2> builderr.log
    checkerr $? "GCC install failed"
    echo "ok"
}

buildedk2()
{
    cd $GLOBAL_CROSS/..
    # Check if EDK2 has already been installed
    if [ -f "$PWD/fw/EFI_${GLOBAL_ARCH}.fd" ] && [ "$REBUILD" != "1" ]
    then
        return
    fi
    if [ ! -d fw ]
    then
        mkdir fw
    fi
    cd fw
    rm -rf edk2
    echo -n "Downloading EDK2..."
    git clone https://github.com/tianocore/edk2.git -b"stable/202011" \
                                                        > build.log 2> builderr.log
    checkerr $? "EDK2 download failed"
    cd edk2 && git submodule update --init > build.log 2> builderr.log
    checkerr $? "EDK2 download failed"
    # Patch EDK2
    patch -p0 -f < ../dep/edk2.patch > /dev/null 2>/dev/null
    echo "ok"
    if [ "$GLOBAL_ARCH" != "aarch64-raspi3" ] 
    then
        echo -n "Building EDK2..."
        export EDK_TOOLS_PATH=$PWD/BaseTools
    fi
    # Build it now
    if [ "$GLOBAL_MACH" = "x86_64" ]
    then
        . $PWD/edksetup.sh > build.log 2> builderr.log
        checkerr $? "EDK2 build failed"
        make -C BaseTools > build.log 2> builderr.log
        checkerr $? "EDK2 build failed"
        build -a X64 -t GCC5 -p OvmfPkg/OvmfPkgX64.dsc -n $GLOBAL_JOBCOUNT > build.log 2> builderr.log
        checkerr $? "EDK2 build failed"
        echo "ok"
        echo -n "Installing EDK2..."
        cp Build/OvmfX64/DEBUG_GCC5/FV/OVMF_CODE.fd ../EFI_${GLOBAL_ARCH}.fd
        cp Build/OvmfX64/DEBUG_GCC5/FV/OVMF_VARS.fd ../EFI_${GLOBAL_ARCH}_VARS.fd
        echo "ok"
    elif [ "$GLOBAL_MACH" = "i686" ]
    then
        . $PWD/edksetup.sh > build.log 2> builderr.log
        checkerr $? "EDK2 build failed"
        make -C BaseTools > build.log 2> builderr.log
        checkerr $? "EDK2 build failed"
        build -a IA32 -t GCC5 -p OvmfPkg/OvmfPkgIA32.dsc -n $GLOBAL_JOBCOUNT > build.log 2> builderr.log
        checkerr $? "EDK2 build failed"
        echo "ok"
        echo -n "Installing EDK2..."
        cp Build/OvmfIa32/DEBUG_GCC5/FV/OVMF_CODE.fd ../EFI_${GLOBAL_ARCH}.fd
        cp Build/OvmfIa32/DEBUG_GCC5/FV/OVMF_VARS.fd ../EFI_${GLOBAL_ARCH}_VARS.fd
        echo "ok"
    elif [ "$GLOBAL_ARCH" = "aarch64-virtio" ]
    then
        export GCC5_AARCH64_PREFIX=aarch64-linux-gnu-
        . $PWD/edksetup.sh > build.log 2> builderr.log
        checkerr $? "EDK2 build failed"
        make -C BaseTools > build.log 2> builderr.log
        checkerr $? "EDK2 build failed"
        build -a AARCH64 -t GCC5 -p ArmVirtPkg/ArmVirtQemu.dsc -n $GLOBAL_JOBCOUNT > build.log 2> builderr.log
        checkerr $? "EDK2 build failed"
        echo "ok"
        echo -n "Installing EDK2..."
        cp Build/ArmVirtQemu-AARCH64/DEBUG_GCC5/FV/QEMU_EFI.fd ../EFI_${GLOBAL_ARCH}.fd
        cp Build/ArmVirtQemu-AARCH64/DEBUG_GCC5/FV/QEMU_VARS.fd ../EFI_${GLOBAL_ARCH}_VARS.fd
        echo "ok"
    elif [ "$GLOBAL_ARCH" = "aarch64-raspi3" ]
    then
        echo -n "Installing EDK2..."
        # Download Raspi3 EFI images
        rm -f RPi3_UEFI_Firmware_v1.35.zip
        rm -rf raspi3-efi
        wget https://github.com/pftf/RPi3/releases/download/v1.35/RPi3_UEFI_Firmware_v1.35.zip \
                > /dev/null 2>&1
        mkdir raspi3-efi
        cd raspi3-efi
        unzip ../RPi3_UEFI_Firmware_v1.35.zip > /dev/null 2>&1
        cp RPI_EFI.fd ../EFI_${GLOBAL_ARCH}.fd
        echo "ok"
    fi
}

# Check that we were launched from build.sh
if [ -z "$GLOBAL_CROSS" ]
then
    panic "must be launched from build.sh"
fi

# Check for build dependencies
builddep

# Create cross compiler directory
if [ ! -d $GLOBAL_CROSS/src ]
then
    mkdir -p $GLOBAL_CROSS/src

# Check if libgmp, mpc, and mpfr have been built
if [ ! -f "$GLOBAL_CROSS/deplib/lib/libgmp.a" ]
then
    builddeplib
fi

fi
cd $GLOBAL_CROSS/src

# Build binutils now
buildbinutils

# Build GCC
buildgcc

# Build EDK2
buildedk2

echo "Dependency build finished"
