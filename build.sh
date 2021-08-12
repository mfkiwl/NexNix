#! /usr/bin/env sh
# build.sh - the top level build system for NexNix
# Distributed with NexNix, licensed under the MIT license
# See LICENSE

# Helper functions
# Prints out an error message
panic()
{
    name=$(basename "$0")
    echo "$name: error: $1"
    exit 1
}

# Prints something on screen
message()
{
    name=$(basename "$0")
    echo "$name: $1"
}

# Check a return value for errors
checkerror()
{
    if [ "$1" != "0" ]
    then
        panic "$2"
    fi
}

help()
{
    # Print out help info
    cat <<end
$(basename $0) - builds a distribution of NexNix
$(basename $0) is a powerful script which is used to build the NexNix operating system
It uses the file conf/nexnix.conf, which contains all configuration data in realtion to NexNix, using an INI like format
See docs/conf.md for more info on it
Below are valid options which can be passed to $(basename $0)
    -h - shows this help screen
    -A ACTION - tells the scripts what it needs to do. These include:
        "build" - builds the system and install in the prefix
        "clean" - removes all intermediate files / folders
        "image" - builds the system, and then creates a disk image
        "dep" - builds dependencies such as the toolchain
    This option is required
    -j JOBS - specifies how many concurrent jobs to use. 1 is the default
    -i IMAGE - specifies the directory to output disk images to. Required for action "image", else unused
    -p PREFIX - specifies directory to install everything into. Required for actions "build", "image", and "dep"
    -a ARCH - specifies the target architecture to build for. Required for actions "build" and "image"
    -D "PARAMS" - contains configuration overrides. This allows for users to override the default configuration in nexnix.conf
    -d - specifies that we are in debug mode
    -P - specifies that profiling is to be enabled. This should be used with -d for optimal resuslts
    -u - specifies users to chown disk images to
end
    exit 0
}

# Parses data in the GLOBAL_ARGS variable
argparse()
{
    arglist="A:hj:i:p:a:dD:Pu:"
    # Start the loop
    while getopts $arglist arg $GLOBAL_ARGS > /dev/null 2> /dev/null; do
        case ${arg} in
            "h")
                # If -h was passed, print out the help screen
                help
                ;;
            "A")
                # Grab the action
                GLOBAL_ACTION="$OPTARG"
                ;;
            "j")
                # Set the job count
                export GLOBAL_JOBCOUNT="$OPTARG"
                ;;
            "i")
                # Grab the image
                export GLOBAL_IMAGE="$OPTARG"
                ;;
            "p")
                # Grab the prefix directory
                export GLOBAL_PREFIX="$OPTARG"
                ;;
            "a")
                export GLOBAL_ARCH="$OPTARG"
                ;;
            "D")
                # Just grab it
                GLOBAL_DEFINES="$OPTARG"
                ;;
            "d")
                export GLOBAL_DEBUG=1
                ;;
            "P")
                export GLOBAL_PROFILE=1
                ;;
            "u")
                export GLOBAL_USER="$OPTARG"
                ;;
            "?")
                panic "invalid argument sent"
        esac
    done

}

# Parses the -D option
urideparse()
{
    # Check if -D was even sent
    if [ ! -z "$GLOBAL_DEFINES" ]
    then
        # Replace every , with a space
        GLOBAL_DEFINES="$(echo $GLOBAL_DEFINES | sed 's/,/ /g')"
        for def in $GLOBAL_DEFINES; do
            # Check for a colon
            iseq=$(echo "$def" | awk '/.:/')
            if [ -z "$iseq" ]
            then
                panic "variable assignment must have a colon"
            fi
            # Split it into two parts
            name=$(echo "$def" | awk -F':' '{print $1}')
            val=$(echo "$def" | awk -F':' '{print $2}')
            # Ensure that both are present
            if [ -z "$name" ] || [ -z "$val" ]
            then
                panic "variable requires name and value"
            fi
            # Shave off quotation marks
            val="$(echo "$val" | sed 's/\"//g')"
            # Shave trailing whitespace off of the name
            name=$(echo "$name" | sed 's/[[:space:]]//g')
            # Set the variable
            eval "$name=\$val"
            # Evaluate variable references inside of the variable
            val=$(eval "echo $val")
            # Export it so subshells can see it
            export $name
            # Set the CMake cache variable
            GLOBAL_CMAKEVARS="${GLOBAL_CMAKEVARS} -D${name}=\"${val}\""
        done
    fi
}

# Checks for data sanity
sanitycheck()
{
    # Check for a valid action
    if [ -z "$GLOBAL_ACTION" ]
    then
        panic "action must be set"
    fi
    foundaction=0
    for action in $GLOBAL_ACTIONS
    do
        if [ "$action" = "$GLOBAL_ACTION" ]
        then
            foundaction=1
            break
        fi
    done
    # Check if the action was found
    if [ $foundaction -eq 0 ]
    then
        panic "invalid action set"
    fi
    # Now diverge based on action
    if [ "$GLOBAL_ACTION" = "clean" ]
    then
        # Exit now, we have all we need
        return
    elif [ "$GLOBAL_ACTION" = "image" ]
    then
        # Check everything image specific
        if [ -z "$GLOBAL_IMAGE" ]
        then
            panic "image must be sent"
        fi
        if [ -z "$GLOBAL_USER" ]
        then
            panic "user must be sent"
        fi
    fi
    # Now check common stuff
    if [ ! -z "$GLOBAL_JOBCOUNT" ]
    then
        # Check if it is a number
        isnum=$(echo $GLOBAL_JOBCOUNT | awk '$0 ~ /[0-9]/')
        if [ -z "$isnum" ]
        then
            panic "job count must be a number"
        fi
    fi
    # Check the prefix
    if [ -z "$GLOBAL_PREFIX" ] && [ "$GLOBAL_ACTION" != "dep" ]
    then
        panic "prefix must be set"
    fi
    # Check that is absolute
    isabs=$(echo "$GLOBAL_PREFIX" | awk '$0 ~ /^\// { print $0 }')
    if [ -z "$isabs" ] && [ "$GLOBAL_ACTION" != "dep" ]
    then
        panic "prefix must be absolute"
    fi
    # Else, check the architecture
    if [ -z "$GLOBAL_ARCH" ] || [ -z "$GLOBAL_ARCHS" ]
    then
        panic "architecture must be set"
    fi
    archfound=0
    for arch in $GLOBAL_ARCHS
    do
        if [ "$arch" = "$GLOBAL_ARCH" ]
        then
            archfound=1
            break
        fi
    done
    if [ $archfound -eq 0 ]
    then
        # Panic about it
        panic "architecture invalid"
    fi
}

# Builds the system
build()
{
    # Create the prefix
    if [ -d $GLOBAL_PREFIX ]
    then
        rm -rf $GLOBAL_PREFIX
    fi
    mkdir -p $GLOBAL_PREFIX
    # Install the headers
    mkdir -p $GLOBAL_PREFIX/usr/include
    cp -r $PWD/usr/include/* $GLOBAL_PREFIX/usr/include
    # Build nexboot first
    ./boot/buildnb.sh
    checkerror $? "build failed"
    # Run Ninja in build directory
    cd build-${GLOBAL_ARCH}
    ninja install -j$GLOBAL_JOBCOUNT
    checkerror $? "build failed"
}

# Configure Ninja
cmakerun()
{
    # Create the build directory
    mkdir build-${GLOBAL_ARCH} > /dev/null 2>&1
    checkerror $? "CMake already configured"
    cd build-${GLOBAL_ARCH}
    # Run CMake. We use eval to resolve variables in GLOBAL_CMAKEVARS
    eval cmake .. "$GLOBAL_CMAKEVARS" -DCMAKE_TOOLCHAIN_FILE=$PWD/../scripts/toolchain.cmake \
        -DCMAKE_INSTALL_PREFIX=$GLOBAL_PREFIX
    checkerror $? "configuring CMake failed"
}

# Main script function. It controls everything else
main()
{
    # Set LC_ALL to C for regex
    export LC_ALL=C
    # Check that getopts is supported
    if ! command -v getopts > /dev/null
    then
        panic "nearly POSIX compliant shell required"
    fi
    # Grab the arguments passed to us
    GLOBAL_ARGS="$@"
    # Parse args, as some configuration file parameters depend on this
    argparse
    # Source the configuration file / script
    . $PWD/scripts/config.sh
    # Parse the arguments again to override the configuration file
    argparse
    # Now we must parse user specified settings overrides
    urideparse
    # Check that it is all valid
    sanitycheck
    # Split it up
    export GLOBAL_MACH=$(echo "$GLOBAL_ARCH" | awk -F'-' '{ print $1 }')
    export GLOBAL_BOARD=$(echo "$GLOBAL_ARCH" | awk -F'-' '{ print $2 }')
    GLOBAL_CMAKEVARS="${GLOBAL_CMAKEVARS} -DGLOBAL_MACH=\"$GLOBAL_MACH\" \
-DGLOBAL_BOARD=\"$GLOBAL_BOARD\""
    # Run based on action now
    if [ "$GLOBAL_ACTION" = "dep" ]
    then
        # Build the toolchain
        bash dep/builddep.sh
        # Build host utilities
        mkdir build-utils && cd build-utils
        cmake ../utils -DCMAKE_INSTALL_PREFIX=$PWD/../utilsbin -G"Ninja"
        ninja install -j$GLOBAL_JOBCOUNT
    elif [ "$GLOBAL_ACTION" = "configure" ]
    then
        # Set the debug variable
        if [ "$GLOBAL_DEBUG" = "1" ]
        then
            GLOBAL_CMAKEVARS="${GLOBAL_CMAKEVARS} -DCMAKE_BUILD_TYPE=\"Debug\""
        else
            GLOBAL_CMAKEVARS="${GLOBAL_CMAKEVARS} -DCMAKE_BUILD_TYPE=\"Release\""
        fi
        # Run CMake
        cmakerun
    elif [ "$GLOBAL_ACTION" = "image" ]
    then
        if [ ! -d $GLOBAL_IMAGE ]
        then
            mkdir -p $GLOBAL_IMAGE
        fi
        # Generate images based on arch and baord
        if [ "$GLOBAL_BOARD" = "pc" ] || [ "$GLOBAL_BOARD" = "virtio" ]
        then
            # Create the disk image
            ./scripts/image.sh -s 2048 -i $GLOBAL_IMAGE/nndisk.img -d $GLOBAL_PREFIX \
                               -p1,300,esp,/boot -p301,2047,ext2,/fsroot -u $GLOBAL_USER
        elif [ "$GLOBAL_BOARD" = "raspi3" ]
        then
            # Copy Raspi3 EFI files
            cp -r fw/raspi3-efi/* $GLOBAL_PREFIX/boot/
            # Change ownership of those copied files
            chown $GLOBAL_USER $GLOBAL_PREFIX/boot/*
            # Create the image
            ./scripts/image.sh -s 2048 -i $GLOBAL_IMAGE/nndisk.img -d $GLOBAL_PREFIX \
                                -p1,300,esp,/boot -p301,2047,ext2,/fsroot -u $GLOBAL_USER
            # Make ESP usable by RPi
            ./utilsbin/mbrwrap $GLOBAL_IMAGE/nndisk.img 1 300
        fi
    elif [ "$GLOBAL_ACTION" = "build" ]
    then
        build
    elif [ "$GLOBAL_ACTION" = "clean" ]
    then
        rm -rf build-*
        rm -rf images-*
        rm -rf rootdir-*
        rm -rf fw/edk2/Build
    fi
}

main "$@"
