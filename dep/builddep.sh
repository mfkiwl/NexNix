#! /usr/bin/env sh
# builddep.sh - builds dependencies of build process
# Distributed with NexNix, licensed under the MIT license
# See LICENSE

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
    echo "$(basename $0): error: $1" 1>&2
}

# Prints an error and exits
panic()
{
    echo "$(basename $0): error: $1" 1>&2
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
cmake, tar, flex, bison, gettext, and, optionally, the ninja build system"
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
    checkdep make
    checkdep gcc
    checkdep tar
    checkdep info
    checkdep perl
    checkdep gettext
    checkdep bison
    checkdep flex
    checkdep cmake
    checkdep wget

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
    cd $GLOBAL_PREFIX/src
    # Check if binutils needs to be built
    if [ -f "$PWD/../bin/$GLOBAL_MACH-elf-ld" ] && [ "$REBUILD" != "1" ]
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
    # Check if PE should be enabled
    if [ "$GLOBAL_MACH" = "i686" -o "$GLOBAL_MACH" = "x86_64" ]
    then
        ../binutils-$binutilsver/configure --prefix=$PWD/../.. --target=$GLOBAL_MACH-elf \
                                --enable-targets=$GLOBAL_MACH-elf,$GLOBAL_MACH-pe --disable-nls \
                                --disable-werror --enable-sysroot > /dev/null 2> /dev/null
    else
        ../binutils-$binutilsver/configure --prefix=$PWD/../.. --target=$GLOBAL_MACH-elf \
                                --disable-nls --disable-werror --enable-sysroot > /dev/null \
                                2> /dev/null
    fi
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
    cd $GLOBAL_PREFIX/src

    # Check if binutils needs to be built
    if [ -f "$PWD/../bin/$GLOBAL_MACH-elf-gcc" ] && [ "$REBUILD" != "1" ]
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
    patch -p0 < $PWD/../../conf/gcc.patch > build.log 2> builderr.log
    checkerr $? "GCC patching failed"
    echo "ok"

    # Build it
    echo -n "Building GCC..."
    mkdir build-gcc && cd build-gcc
    ../gcc-$gccver/configure --prefix=$PWD/../.. --target=$GLOBAL_MACH-elf --enable-languages=c \
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

# Check that we were launched from build.sh
if [ -z "$GLOBAL_PREFIX" ]
then
    panic "must be launched from build.sh"
fi

# Check for build dependencies
builddep

# Create cross compiler directory
if [ ! -d $GLOBAL_PREFIX ]
then
    mkdir -p $GLOBAL_PREFIX/src
fi
cd $GLOBAL_PREFIX/src

# Check if libgmp, mpc, and mpfr have been built
if [ ! -f "$PWD/../deplib/lib/libgmp.a" ]
then
    builddeplib
fi

# Build binutils now
buildbinutils

# Build GCC
buildgcc

echo "Dependency build finished"
