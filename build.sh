#! /bin/sh
# build.sh - contains main build script
# Distributed with NexNix, licensed under the MIT license
# See LICENSE

# Argument variables
prefix=
debug=off
arch=
board=
action=build
target=all

archs="i686-pc x86_64-pc x86_64-efi riscv32-virt riscv64-virt end"
actions="build prepare clean end"
targets="all toolchain nexboot end"
buildtar="nexboot"
gccver=10.2.0
binutilver=2.35

# Parses an argument's data
arghandle()
{
    # Grab actual argument
    arg=$(echo "$1" | awk -F "=" '{print $1}')
    # Now figure out what it is
    if [ "$arg" = "--help" ]
    then
        # Print out help
        echo "$0 - manages build process for NexNix"
        echo "Usage: $0 [OPTIONS]"
        echo "Supported options:"
        echo "--help\t\t\tprint out this screen"
        echo "--arch=ARCH\t\tsets what arch is to be used"
        echo "--archs\t\tprint all available archs"
        echo "--target=TARGET\t\tsets what target is to be built"
        echo "--action=ACTION\t\tspecifies what sould be done. Can be build or prepare"
        echo "--debug\t\t\tif set, nexware will be built in debug mode"
        echo "--prefix=DIR\t\tsets what directory nexware files should be copied to"
        exit 0
    elif [ "$arg" = "--archs" ]
    then
        echo "Available archs:"
        echo "i686-pc x86_64-pc riscv32-virt"
        echo "Archs are split into 2 parts: the CPU architecture, and the board for that cpu"
    elif [ "$arg" = "--arch" ]
    then
        argdata=$(echo "$1" | awk -F "=" '{print $2}')
        if [ -z "$argdata" ]
        then
            echo "$0: --arch requires an argument"
            exit 1
        fi
        # Validate and parse the arch
        # Now check if the contents are valid
        for arch in $archs
        do
            if [ "$argdata" = "$arch" ] && [ "$argdata" != "end" ]
            then
                break
            elif [ "$arch" = "end" ]
            then
                echo "$0: Invalid arch set"
                exit 1
            fi
        done
        argarch=$(echo "$argdata" | awk -F "-" '{print $1}')
        if [ -z "$argarch" ]
        then
            echo "$0: arch not set"
            exit 1
        fi
        argboard=$(echo "$argdata" | awk -F "-" '{print $2}')
        if [ -z "$argboard" ]
        then
            echo "$0: board not set"
            exit 1
        fi
        # Set the vars
        board=$argboard
        arch=$argarch
    # If the user specified what to do
    elif [ "$arg" = "--action" ]
    then
        # Get the action wanted
        argdata=$(echo "$1" | awk -F "=" '{print $2}')
        if [ -z "$argdata" ]
        then
            echo "$0: No action specified"
            exit 1
        fi
        # Loop through the actions
        for act in $actions
        do
            if [ "$argdata" = "$act" ] && [ "$argdata" != "end" ]
            then
                break
            elif [ "$act" = "end" ]
            then
                echo "$0: Invalid action set"
                exit 1
            fi
        done
        action=$argdata
    # If the user specified what to build
    elif [ "$arg" = "--target" ]
    then
        # Get the target wanted
        argdata=$(echo "$1" | awk -F "=" '{print $2}')
        if [ -z "$argdata" ]
        then
            echo "$0: No target specified"
            exit 1
        fi
        # Loop through the actions
        for tar in $targets
        do
            if [ "$argdata" = "$tar" ] && [ "$argdata" != "end" ]
            then
                break
            elif [ "$tar" = "end" ]
            then
                echo "$0: Invalid target set"
                exit 1
            fi
        done
        target=$argdata
    elif [ "$arg" = "--debug" ]
    then
        debug=all
    elif [ "$arg" = "--prefix" ]
    then
        # Get the dir wanted
        argdata=$(echo "$1" | awk -F "=" '{print $2}')
        if [ -z "$argdata" ]
        then
            echo "$0: No prefix specified"
            exit 1
        fi
        prefix=$argdata
    else
        echo "$0: Invalid argument sent"
        exit 1
    fi
}

# Prepares a target
targetprep() {
    tar=$1
    # Figure out what to do
    if [ "$tar" = "nexboot" ]
    then
        cd $tar && rm -rf build-$arch && mkdir build-$arch && cd build-$arch
        cmake .. -DDEBUG:STRING=$debug -DARCH:STRING=$arch -DBOARD:STRING=$board -DCROSS:STRING=$CROSS \
            -DCMAKE_TOOLCHAIN_FILE:FILEPATH=../../toolchain-gnu.cmake -DCMAKE_INSTALL_PREFIX:STRING=$PWD/$prefix
    fi
}

# Setup vars for argument loop
args=$@
# Loop through the arguments
for arg in $args
do
# Parse this argument
arghandle $arg
done
# Make sure required arguments were sent
# Check prefix
if [ -z "$prefix" ] && [ "$action" = "prepare" ]
then
    echo "$0: Prefix must be set"
    exit 1
fi
# Check arch
if [ -z "$arch" ] || [ -z "$board" ]
then
    echo "$0: Arch must be set"
    exit 1
fi

# Parse cpus
ncpu=1

# Now diverge execution based on action
if [ "$action" = "prepare" ]
then
    # First, check if we need to build to toolchain
    if [ "$target" = "toolchain" ]
    then
        # Create the prefix
        if [ ! -d "$prefix" ]
        then
            mkdir -p $prefix
        fi
        prefix="$(pwd)/$prefix"
        # Switch to the prefix directory
        cd $prefix
        mkdir src && cd src
        # Download gcc and binutils source
        wget https://ftp.gnu.org/gnu/gcc/gcc-${gccver}/gcc-${gccver}.tar.xz
        wget https://ftp.gnu.org/gnu/binutils/binutils-${binutilver}.tar.xz
        # Extract source
        tar -xf gcc-${gccver}.tar.xz
        tar -xf binutils-${binutilver}.tar.xz
        # Now create binutils build folder
        cd binutils-${binutilver} && mkdir build && cd build
        # Configure it
        ../configure --target=${arch}-elf --prefix="$prefix" --disable-nls --disable-werror --with-sysroot
        # Build it
        make -j$(nproc)
        make install -j$(nproc)
        # Now do the same to GCC
        cd ../../gcc-${gccver} && mkdir build && cd build
        ../configure --target=${arch}-elf --prefix="$prefix" --without-headers --enable-languages=c --disable-nls
        make all-gcc -j$(nproc)
        make all-target-libgcc -j$(nproc)
        make install-gcc -j$(nproc)
        make install-target-libgcc -j$(nproc)
        # We are done now
        echo "$0: Cross toolchain built. Please set variable CROSS to ${prefix}/bin"
    # If we want to build everything
    elif [ "$target" = "all" ]
    then
        # Create the prefix
        if [ ! -d "$prefix" ]
        then
            mkdir -p $prefix/boot
        fi
        # Build all first party targets. They are available locally
        for tar in $buildtar
        do
            targetprep $tar  
        done
    # If we want to build a certain target
    else
        # Create the prefix
        if [ ! -d "$prefix" ]
        then
            mkdir -p $prefix/boot
            mkdir -p $prefix/usr/include
        fi
        for tar in $buildtar
        do
            if [ "$tar" = "$target" ]
            then
                targetprep $tar
            fi
        done
        # Print out an error
        echo "$0 - Target $target does not exist!"
        exit 1
    fi
elif [ "$action" = "build" ]
then
    # Build the project(s) wanted
    if [ "$target" = "all" ]
    then
        # Install the headers
        cp include/* rootdir/usr/include/
        # Go through all Nexware projects first
        for tar in $nextargets
        do
            cd $tar && rm -rf build-$arch && mkdir build-$arch && cd build-$arch
            make install
        done
    # If we want to build a certain target
    else
        # Figure out what type this target is
        for tar in $nextargets
        do
            if [ "$tar" = "$target" ]
            then
                cd $tar && rm -rf build-$arch && mkdir build-$arch && cd build-$arch
                make install
                exit 0
            fi
        done
        # Print out an error
        echo "$0 - Target $target does not exist!"
        exit 1
    fi
elif [ "$action" = "clean" ]
then
    # Check prefix
    if [ -z "$prefix" ]
    then
        echo "$0: Prefix must be set"
        exit 1
    fi
    # Delete all downloaded things
    rm -rf cross
    rm -rf $prefix
    # Now delete the build folders
    for tar in $nextargets
    do
        cd $tar && rm -rf build-$arch
        cd ..
    done
else
    echo "$0: Invalid action"
    exit 1
fi
