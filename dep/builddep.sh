#! /usr/bin/env sh
# builddep.sh - builds dependencies of build process
# Distributed with NexNix, licensed under the MIT license
# See LICENSE

error()
{
    echo "$(basename $0): error: $1"
    exit 1
}

checkerr()
{
    if [ "$1" != 0 ]
    then
        error "$2"
    fi
}

# Prepare directory for toolchain
rm -rf cross
mkdir -p cross/src && cd cross/src
mkdir ../deplib

# Download libgmp
wget https://ftp.gnu.org/gnu/gmp/gmp-6.2.1.tar.xz
checkerr $? "libgmp download failed"
tar xf gmp-6.2.1.tar.xz
# Build it
mkdir build-gmp
cd build-gmp
../gmp-6.2.1/configure --prefix=$PWD/../../deplib --disable-shared
checkerr $? "libgmp configure failed"
make -j$GLOBAL_JOBCOUNT
checkerr $? "libgmp build failed"
make check -j$GLOBAL_JOBCOUNT
checkerr $? "libgmp check failed"
make install -j$GLOBAL_JOBCOUNT
checkerr $? "libgmp install failed"
cd ..

# Download libmpfr
wget https://ftp.gnu.org/gnu/mpfr/mpfr-4.1.0.tar.xz
checkerr $? "libmpfr download failed"
tar xf mpfr-4.1.0.tar.xz
# Build it
mkdir build-mpfr
cd build-mpfr
../mpfr-4.1.0/configure --prefix=$PWD/../../deplib --disable-shared --with-gmp=$PWD/../../deplib
checkerr $? "libmpfr configure failed"
make -j$GLOBAL_JOBCOUNT
checkerr $? "libmpfr build failed"
make install -j$GLOBAL_JOBCOUNT
checkerr $? "libmpfr install failed"
cd ..

# Download libmpc
wget https://ftp.gnu.org/gnu/mpc/mpc-1.2.1.tar.gz
checkerr $? "libmpc download failed"
tar xf mpc-1.2.1.tar.gz
# Build it
mkdir build-mpc
cd build-mpc
../mpc-1.2.1/configure --prefix=$PWD/../../deplib --disable-shared --with-gmp=$PWD/../../deplib --with-mpfr=$PWD/../../deplib
checkerr $? "libmpc configure failed"
make -j$GLOBAL_JOBCOUNT
checkerr $? "libmpc build failed"
make install -j$GLOBAL_JOBCOUNT
checkerr $? "libmpc install failed"
cd ..

# Download binutils
wget https://ftp.gnu.org/gnu/binutils/binutils-2.36.tar.gz
checkerr $? "binutils download failed"
tar xf binutils-2.36.tar.gz
mkdir build-binutils && cd build-binutils

# Loop through every architecture and build binutils for it
for mach in $GLOBAL_MACHS
do
    if [ "$mach" = "x86_64" ]
    then
        ../binutils-2.36/configure --prefix=$PWD/../.. --target=${mach}-elf --enable-targets=${mach}-elf,${mach}-pe --disable-nls --enable-sysroot --disable-werror
        checkerr $? "binutils configure failed"
    else
        ../binutils-2.36/configure --prefix=$PWD/../.. --target=${mach}-elf --disable-nls --enable-sysroot --disable-werror
        checkerr $? "binutils configure failed"
    fi
    gmake -j$GLOBAL_JOBCOUNT
    checkerr $? "binutils build failed"
    gmake install -j$GLOBAL_JOBCOUNT
    checkerr $? "binutils install failed"
    # Remove current binutils build directory for next build
    cd .. && rm -rf build-binutils
    mkdir build-binutils && cd build-binutils
done
cd ..

# Download GCC
wget https://ftp.gnu.org/gnu/gcc/gcc-10.2.0/gcc-10.2.0.tar.gz
checkerr $? "GCC download failed"
tar xf gcc-10.2.0.tar.gz
patch -p0 < $PWD/../../conf/gcc.patch
checkerr $? "Patching GCC failed"
mkdir build-gcc && cd build-gcc

# Loop through every architecture and build for it
for mach in $GLOBAL_MACHS
do
    ../gcc-10.2.0/configure --prefix=$PWD/../.. --target=${mach}-elf --disable-nls --enable-languages=c --without-headers --disable-shared --with-gmp=$PWD/../../deplib \
                            --with-mpfr=$PWD/../../deplib --with-mpc=$PWD/../../deplib
    checkerr $? "GCC configure failed"
    gmake all-gcc -j$GLOBAL_JOBCOUNT
    checkerr $? "building GCC failed"
    gmake all-target-libgcc -j$GLOBAL_JOBCOUNT
    checkerr $? "building libgcc failed"
    gmake install-gcc -j$GLOBAL_JOBCOUNT
    checkerr $? "installing GCC failed"
    gmake install-target-libgcc -j$GLOBAL_JOBCOUNR
    checkerr $? "installing libgcc failed"
    # Prepare next build
    cd .. && rm -rf build-gcc
    mkdir build-gcc && cd build-gcc
done

# Cleanup build
echo "$(basename $0): cleaning up..."
cd ../..
rm -rf src
