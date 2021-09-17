#! /usr/bin/env sh
# build.sh - the top level build system for NexNix
# SPDX-License-Identifier: ISC

# Version info
export majorver=0
export minorver=0
export patchlevel=1

# Base variables
export GLOBAL_ACTIONS="clean dep image configure build dist"
export GLOBAL_JOBCOUNT=1
export GLOBAL_ARCHS="i386-pc x86_64-pc riscv64-virt"
export i386pc_configs="i386pc i386pc-iso"
export riscv64virt_configs="riscv64virt"
export x86_64pc_configs="x86_64pc x86_64pc-iso"
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
Below are valid options which can be passed to $(basename $0)
  -h - shows this help screen

  -A ACTION - tells the scripts what it needs to do. These include:
        "build" - builds the system and install in the prefix
        "clean" - removes all intermediate files / folders
        "image" - builds the system, and then creates a disk image
        "dep" - builds dependencies such as the toolchain
        "dist" - creates a distribution into a tarball
    This option is required

  -j JOBS -   specifies how many concurrent jobs to use. 1 is the default

  -i IMAGE -  specifies the directory to output disk images to. 
              Required for actions "clean" and "image", else unused

  -p PREFIX - specifies directory to install everything into. 
              Required for actions "configure", "image", "clean", and "dep"

  -a ARCH -   specifies the target architecture to build for.  
              Required for actions "configure", "build", "clean", "dep", and "image"

  -D "OPT" -  contains configuration overrides. This allows for you to override 
              the default configuration in nexnix.cfg

  -d          specifies that we are in debug mode

  -P          specifies that profiling is to be enabled. 
              This should be used with -d for optimal results

  -u          specifies user to chown images to. Required for action "image"

  -c          specifies the configuration to build. 
              Required for action "image"

  -o          specifies image configuration output directory. 
              Required for actions "image" and "clean"
  
  -b          specifies build output directory for intermediate files.
              Required for actions "configure" and "clean"

  -t          specifies make(1) target to run

end
    exit 0
}

# Parses data in the GLOBAL_ARGS variable
argparse()
{
    arglist="A:hj:i:p:a:dD:Pu:c:o:b:t:"
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
                GLOBAL_DEFINES="$GLOBAL_DEFINES GLOBAL_IMAGE:\"$GLOBAL_IMAGE\""
                ;;
            "p")
                # Grab the prefix directory
                export GLOBAL_PREFIX="$OPTARG"
                # Add it to the user overrides. Kind of a hack, but it works
                GLOBAL_DEFINES="$GLOBAL_DEFINES GLOBAL_PREFIX:\"$GLOBAL_PREFIX\""
                ;;
            "a")
                export GLOBAL_ARCH="$OPTARG"
                ;;
            "D")
                # Just grab it
                GLOBAL_DEFINES="$GLOBAL_DEFINES $OPTARG"
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
                GLOBAL_DEFINES="$GLOBAL_DEFINES GLOBAL_CONFIG:\"$GLOBAL_CONFIG\""
                ;;
            "o")
                export GLOBAL_OUTPUT="$OPTARG"
                GLOBAL_DEFINES="$GLOBAL_DEFINES GLOBAL_OUTPUT:\"$GLOBAL_OUTPUT\""
                ;;
            "b")
                export GLOBAL_BUILDDIR="$OPTARG"
                GLOBAL_DEFINES="$GLOBAL_DEFINES GLOBAL_BUILDDIR:\"$GLOBAL_BUILDDIR\""
                ;;
            "t")
                export GLOBAL_TARGET="$OPTARG"
                ;;
            "?")
                panic "invalid argument specified"
                ;;
        esac
    done

}

# Parses the -D option
urideparse()
{
    # Check if -D was even sent
    if [ ! -z "$GLOBAL_DEFINES" ]
    then
        # Create scripts file and empty it
        cat /dev/null > scripts/scripts-${GLOBAL_ARCH}.cfg
        # Replace every , with a space
        GLOBAL_DEFINES="$(echo $GLOBAL_DEFINES | sed 's/,/ /g')"
        for def in $GLOBAL_DEFINES
        do
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
            # Check if this is quoted
            isquote=$(echo "$val" | awk '/^"/')
            # Shave off quotation marks
            val="$(echo "$val" | sed 's/\"//g')"
            # Shave trailing whitespace off of the name
            name=$(echo "$name" | sed 's/[[:space:]]//g')
            # Set the variable
            eval "$name=\$val"
            # Evaluate variable references inside of the variable
            val=$(eval "echo $val")
            # Add it to scripts.cfg, first restoring quotes
            if [ ! -z "$isquote" ]
            then
                val="\"$val\""
            fi
            printf "$(cat scripts/scripts-$GLOBAL_ARCH.cfg)\n$name=$val\n" > scripts/scripts-${GLOBAL_ARCH}.cfg
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
    # Action dist has no arguments needed
    if [ "$GLOBAL_ACTION" = "dist" ]
    then
        return
    fi
    # Now diverge based on action
    if [ "$GLOBAL_ACTION" = "configure" ]
    then
        # Check everything image specific
        if [ -z "$GLOBAL_IMAGE" ]
        then
            panic "image path not specified"
        fi
        # Check that it is absolute
        isabs=$(echo "$GLOBAL_IMAGE" | awk '$0 ~ /^\// { print $0 }')
        if [ -z "$isabs" ]
        then
            panic "image path must be absolute"
        fi
        if [ -z "$GLOBAL_OUTPUT" ]
        then
            panic "output directory not specified"
        fi
        # Check that it is absolute
        isabs=$(echo "$GLOBAL_OUTPUT" | awk '$0 ~ /^\// { print $0 }')
        if [ -z "$isabs" ]
        then
            panic "output directory must be absolute"
        fi
        if [ -z "$GLOBAL_PREFIX" ]
        then
            panic "prefix not specified"
        fi
        # Check that it is absolute
        isabs=$(echo "$GLOBAL_PREFIX" | awk '$0 ~ /^\// { print $0 }')
        if [ -z "$isabs" ]
        then
            panic "prefix must be absolute"
        fi
        if [ -z "$GLOBAL_BUILDDIR" ]
        then
            panic "build directory not specified"
        fi
        # Check that it is absolute
        isabs=$(echo "$GLOBAL_BUILDDIR" | awk '$0 ~ /^\// { print $0 }')
        if [ -z "$isabs" ]
        then
            panic "build directory must be absolute"
        fi
        if [ -z "$GLOBAL_CONFIG" ]
        then
            panic "configuration not specified"
        fi
    fi
    if [ "$GLOBAL_ACTION" = "image" ]
    then
        if [ -z "$GLOBAL_USER" ]
        then
            panic "user not specified"
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
    
    # Check the architecture
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
    # Run make
    gmake -j$GLOBAL_JOBCOUNT -Otarget ${GLOBAL_TARGET}
    checkerror $? "build failed"
}

# Generates a disk image
imagegen()
{
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
    elif [ "$GLOBAL_ARCH" = "riscv64-virt" ]
    then
        foundconfig=0
        for config in $riscv64virt_configs
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
    fi
    if [ "$foundconfig" = "0" ]
    then
        panic "invalid configuration specified"
    fi
    # Generate it
    ./scripts/osconfgen.sh -cconfigs/conf-${GLOBAL_CONFIG}.txt -p$GLOBAL_PREFIX -i$GLOBAL_IMAGE \
                        -o${GLOBAL_OUTPUT} -u$GLOBAL_USER
    checkerror $? "image generation failed"
}

# Configures everything
configure()
{
    # Generate the configuration script
    ./utilsbin/confgen scripts/nexnix.cfg config/config-$GLOBAL_ARCH.sh \
                        include/${GLOBAL_ARCH}.h
    checkerror $? "unable to generate configuration"
    . $PWD/config/config-$GLOBAL_ARCH.sh
    # Remove "scripts" from projects list
    GLOBAL_PROJECTS=$(echo "$GLOBAL_PROJECTS" | sed 's/scripts//')
    export GLOBAL_PROJECTS
    # If make config has already been run, exit
    if [ -d $GLOBAL_PREFIX ]
    then
        return
    fi
    # Create the prefix
    mkdir -p $GLOBAL_PREFIX
    # Generate ver.h
    echo "#define NEXNIX_VERMAJ ${majorver}
#define NEXNIX_VERMIN ${minorver}
#define NEXNIX_VERPATCH ${patchlevel}" > $PWD/include/ver.h
    # Configure make now
    gmake config
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
    if [ "$GLOBAL_ACTION" != "dep" ] && [ "$GLOBAL_ACTION" != "configure" ] \
        && [ "$GLOBAL_ACTION" != "dist" ]
    then
        if [ ! -f  "$PWD/config/config-${GLOBAL_ARCH}.sh" ]
        then
            panic "configure must be run before $GLOBAL_ACTION"
        fi
        . $PWD/config/config-$GLOBAL_ARCH.sh
        # Remove "scripts" from projects list
        GLOBAL_PROJECTS=$(echo "$GLOBAL_PROJECTS" | sed 's/scripts//')
        export GLOBAL_PROJECTS
    fi
    # Parse args to override configuration file
    argparse
    # Split up the architecture into machine and board
    export GLOBAL_MACH=$(echo "$GLOBAL_ARCH" | awk -F'-' '{ print $1 }')
    export GLOBAL_BOARD=$(echo "$GLOBAL_ARCH" | awk -F'-' '{ print $2 }')
    # Run based on action now
    if [ "$GLOBAL_ACTION" = "dep" ]
    then
        # Build the toolchain
        bash scripts/builddep.sh
        checkerror $? "dependency build failed"
        # Create host utility binary directory
        mkdir -p utilsbin
        # Build host utilities
        gmake -j8 -C utils --no-print-directory
    elif [ "$GLOBAL_ACTION" = "dist" ]
    then
        # Run make
        make dist
    elif [ "$GLOBAL_ACTION" = "configure" ]
    then
        if [ ! -d $PWD/config ]
        then
            mkdir $PWD/config
        fi
        configure
    elif [ "$GLOBAL_ACTION" = "image" ]
    then
        imagegen
    elif [ "$GLOBAL_ACTION" = "build" ]
    then
        build
    elif [ "$GLOBAL_ACTION" = "clean" ]
    then
        # Tell make to clean out build files
        make clean -j${GLOBAL_JOBCOUNT} -Otarget
        rm -rf ${GLOBAL_IMAGE}
        rm -rf ${GLOBAL_PREFIX}
        rm -rf ${GLOBAL_OUTPUT}
        rm -rf ${GLOBAL_BUILDDIR}
        rm -rf fw/edk2/Build/MdeModule/*/*/boot
        rm -f config/config-${GLOBAL_ARCH}.sh
        rm -f include/${GLOBAL_ARCH}.h
        rm -f include/ver.h
        rm -f scripts/scripts-${GLOBAL_ARCH}.cfg
    fi
}

main "$@"
