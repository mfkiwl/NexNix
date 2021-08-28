#! /usr/bin/env sh
# build.sh - the top level build system for NexNix
# SPDX-License-Identifier: ISC

# Base variables
export GLOBAL_ACTIONS="clean dep image configure build"
export GLOBAL_JOBCOUNT=1
export GLOBAL_ARCHS="x86_64-pc i386-pc aarch64-sr"
export i386pc_configs="i386pc-legacy i386pc"
export x86_64pc_configs="x86_64pc"
export aarch64sr_configs="aarch64sr"
export GLOBAL_CROSS="$PWD/cross"

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
    -c - specifies the configuration to build
end
    exit 0
}

# Parses data in the GLOBAL_ARGS variable
argparse()
{
    arglist="A:hj:i:p:a:dD:Pu:c:"
    # Start the loop
    while getopts $arglist arg $GLOBAL_ARGS > /dev/null 2>&1; do
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
            "c")
                export GLOBAL_CONFIG="$OPTARG"
                ;;
            "?")
                panic "invalid argument specified"
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
        panic "action not specifed"
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
    if [ "$GLOBAL_ACTION" = "image" ] || [ "$GLOBAL_ACTION" = "clean" ]
    then
        # Check everything image specific
        if [ -z "$GLOBAL_IMAGE" ]
        then
            panic "image not specified"
        fi
        if [ "$GLOBAL_ACTION" = "image" ]
        then
            if [ -z "$GLOBAL_USER" ]
            then
                panic "user not specified"
            fi
            if [ -z "$GLOBAL_CONFIG" ]
            then
                panic "configuration not specified"
            fi
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
        panic "prefix not specified"
    fi
    # Check that is absolute
    isabs=$(echo "$GLOBAL_PREFIX" | awk '$0 ~ /^\// { print $0 }')
    if [ -z "$isabs" ] && [ "$GLOBAL_ACTION" != "dep" ]
    then
        panic "prefix must be absolute"
    fi
    # Clean action now returns
    if [ "$GLOBAL_ACTION" = "clean" ]
    then
        return
    fi
    # Else, check the architecture
    if [ -z "$GLOBAL_ARCH" ]
    then
        panic "architecture not specified"
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
    make install -j$GLOBAL_JOBCOUNT
    checkerror $? "build failed"
}

# Configure Ninja
cmakerun()
{
    # Create the build directory
    if [ ! -d build-${GLOBAL_ARCH} ]
    then
        mkdir build-${GLOBAL_ARCH}
    fi
    cd build-${GLOBAL_ARCH}
    # Run CMake. We use eval to resolve variables in GLOBAL_CMAKEVARS
    eval cmake .. -DCMAKE_INSTALL_PREFIX=$GLOBAL_PREFIX $GLOBAL_CMAKEVARS \
                -DCMAKE_TOOLCHAIN_FILE="$PWD/../scripts/toolchain.cmake" --no-warn-unused-cli
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
    # Parse args
    argparse
    # Now we must parse user specified settings overrides
    urideparse
    # Check that it is all valid
    sanitycheck
    # Source the configuration script
    if [ "$GLOBAL_ACTION" != "dep" ] && [ "$GLOBAL_ACTION" != "configure" ] && [ "$GLOBAL_ACTION" != "clean" ]
    then
        . $PWD/config/config-$GLOBAL_ARCH.sh
    fi
    # Parse args to override configuration file
    argparse
    # Split up the architecture into machine and board
    export GLOBAL_MACH=$(echo "$GLOBAL_ARCH" | awk -F'-' '{ print $1 }')
    export GLOBAL_BOARD=$(echo "$GLOBAL_ARCH" | awk -F'-' '{ print $2 }')
    GLOBAL_CMAKEVARS="${GLOBAL_CMAKEVARS} -DGLOBAL_MACH=\"$GLOBAL_MACH\" \
-DGLOBAL_BOARD=\"$GLOBAL_BOARD\" -DGLOBAL_CROSS=\"$GLOBAL_CROSS\""
    # Run based on action now
    if [ "$GLOBAL_ACTION" = "dep" ]
    then
        # Build the toolchain
        bash dep/builddep.sh
        # Build host utilities
        if [ ! -d build-utils ]
        then
            mkdir build-utils
        fi
        cd build-utils
        cmake ../utils -DCMAKE_INSTALL_PREFIX=$PWD/../utilsbin
        make install -j$GLOBAL_JOBCOUNT
    elif [ "$GLOBAL_ACTION" = "configure" ]
    then
        if [ ! -d $PWD/config ]
        then
            mkdir $PWD/config
        fi
        # Generate the configuration script
        ./utilsbin/confgen scripts/nexnix.cfg config/config-$GLOBAL_ARCH.sh \
                            $PWD/usr/include/config-${GLOBAL_ARCH}.h
        checkerror $? "unable to generate configuration"
        . $PWD/config/config-$GLOBAL_ARCH.sh
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
        if [ "$GLOBAL_ARCH" = "i386-pc" ]
        then
            foundconfig=0
            for config in $i386pc_configs
            do
                if [ "$config" = "$GLOBAL_CONFIG" ]
                then
                    foundconfig=1
                fi
            done
        elif [ "$GLOBAL_ARCH" = "x86_64-pc" ]
        then
            foundconfig=0
            for config in $x86_64pc_configs
            do
                if [ "$config" = "$GLOBAL_CONFIG" ]
                then
                    foundconfig=1
                fi
            done
        elif [ "$GLOBAL_ARCH" = "aarch64-sr" ]
        then
            foundconfig=0
            for config in $aarch64sr_configs
            do
                if [ "$config" = "$GLOBAL_CONFIG" ]
                then
                    foundconfig=1
                fi
            done
        if [ "$foundconfig" = "0" ]
        then
            panic "invalid configuration specified"
        fi
        # Generate it
        ./scripts/osconfgen.sh -cconfigs/conf-${GLOBAL_CONFIG}.txt -p$GLOBAL_PREFIX -i$GLOBAL_IMAGE \
                            -ooutput-${GLOBAL_CONFIG} -u$GLOBAL_USER
        fi
    elif [ "$GLOBAL_ACTION" = "build" ]
    then
        build
    elif [ "$GLOBAL_ACTION" = "clean" ]
    then
        rm -rf build-*
        rm -rf ${GLOBAL_IMAGE}-*
        rm -rf ${GLOBAL_PREFIX}-*
        rm -rf fw/edk2/Build
        rm -rf config
        rm -f usr/include/config-*.h
    fi
}

main "$@"
