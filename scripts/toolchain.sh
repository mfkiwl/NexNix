#! /bin/sh
# toolchain.sh - builds GNU toolchain
# Distributed with NexNix, licensed under the MIT license
# See LICENSE

# Check variables
if [ -z "$PREFIX" ]
then
    echo "$0: Prefix not set!"
    exit 1
fi

# Check if PREFIX is an absolute path or not
isabs=$(echo $PREFIX | grep -o '^/')
if [ "$isabs" != '/' ]
then
    echo "$0: PREFIX must be an absolute path!"
    exit 0
fi

# Create the prefix
mkdir -p $PREFIX
cd $PREFIX

if [ -z "$JOBCOUNT" ]
then
    JOBCOUNT=$(nproc)
fi

if [ -z "$ARCHS" ]
then
    ARCHS="x86_64-elf aarch64-elf riscv64-elf"
fi

if [ -z "$GCCVER" ]
then
    GCCVER=10.2.0
fi

if [ -z "$BINUTILSVER" ]
then
    BINUTILSVER=2.36
fi

# Download GCC
mkdir src && cd src
wget https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILSVER}.tar.xz
if [ "$?" != "0" ]
then
    echo "$0: An error occurred. Quiting..."
    # Cleanup directory
    cd $PREFIX/.. && rm -rf cross
    exit 1
fi
wget http://mirrors.concertpass.com/gcc/releases/gcc-${GCCVER}/gcc-${GCCVER}.tar.xz
if [ "$?" != "0" ]
then
    echo "$0: An error occurred. Quiting..."
    # Cleanup directory
    cd $PREFIX/.. && rm -rf cross
    exit 1
fi
# Extract GCC and Binutils
tar xf binutils-${BINUTILSVER}.tar.xz
tar xf gcc-${GCCVER}.tar.xz

for ARCH in $ARCHS
do
    # Build binutils first
    mkdir binutils-${BINUTILSVER}/build && cd binutils-${BINUTILSVER}/build
    ../configure --target=$ARCH --prefix=$PREFIX/$ARCH --enable-sysroot --disable-werror --disable-nls
    if [ "$?" != "0" ]
    then
        echo "$0: An error occurred. Quiting..."
        # Cleanup directory
        cd $PREFIX/..  && rm -rf cross
        exit 1
    fi
    make -j$JOBCOUNT
    if [ "$?" != "0" ]
    then
        echo "$0: An error occurred. Quiting..."
        # Cleanup directory
        cd $PREFIX/.. && rm -rf cross
        exit 1
    fi
    make install -j $JOBCOUNT
    if [ "$?" != "0" ]
    then
        echo "$0: An error occurred. Quiting..."
        # Cleanup directory
        cd $PREFIX/.. && rm -rf cross
        exit 1
    fi
    # Now build GCC and libgcc
    cd ../..
    rm -rf binutils-${BINUTILSVER}/build
    # Check if we need red zone patch
    if [ "$ARCH" = "x86_64-elf" ]
    then
        # Copy the patch file
        cp ../../conf/gcc.patch $PWD/gcc.patch
        patch -p0 < gcc.patch
    fi
    mkdir gcc-${GCCVER}/build && cd gcc-${GCCVER}/build
    ../configure --target=$ARCH --prefix=$PREFIX/$ARCH --disable-werror --enable-languages=c --without-headers
    if [ "$?" != "0" ]
    then
        echo "$0: An error occurred. Quiting..."
        cd $PREFIX/.. && rm -rf cross
        exit 1
    fi
    make all-gcc -j$JOBCOUNT
    if [ "$?" != "0" ]
    then
        echo "$0: An error occurred. Quiting..."
        # Cleanup directory
        cd $PREFIX/.. && rm -rf cross
        exit 1
    fi
    make install-gcc -j$JOBCOUNT
    if [ "$?" != "0" ]
    then
        echo "$0: An error occurred. Quiting..."
        # Cleanup directory
        cd $PREFIX/.. && rm -rf cross
        exit 1
    fi
    make all-target-libgcc -j$JOBCOUNT
    if [ "$?" != "0" ]
    then
        echo "$0: An error occurred. Quiting..."
        # Cleanup directory
        cd $PREFIX/.. && rm -rf cross
        exit 1
    fi
    make install-target-libgcc -j$JOBCOUNT
    if [ "$?" != "0" ]
    then
        echo "$0: An error occurred. Quiting..."
        # Cleanup directory
        cd $PREFIX/.. && rm -rf cross
        exit 1
    fi
    # Now go back to prefix directory for next build
    cd $PREFIX/src
    rm -rf gcc-${GCCVER}/build
done

echo "$0: Building complete! Please export variable CROSS to equal the bin directory of the desired compiler"
