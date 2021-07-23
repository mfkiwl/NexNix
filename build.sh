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
    -P - specifies that profiling is to be enabled. This should be used with -d for optimal results
    -n - use Ninja as the build system.  Requires package ninja to be installed. Note that on Debian, this package is "ninja-build"
end
    exit 0
}
# Main variables
GLOBAL_ARGS=
GLOBAL_ACTION=
GLOBAL_ACTIONS="clean image dep build"
export GLOBAL_JOBCOUNT=1
export GLOBAL_PREFIX=
export GLOBAL_IMAGE=
export GLOBAL_ARCH=
export GLOBAL_DEBUG=0
export GLOBAL_PROFILE=0
GLOBAL_DEFINES=
GLOBAL_CMAKEVARS=
GLOBAL_USENINJA=0

# Parses data in the GLOBAL_ARGS variable
argparse()
{
    arglist="A:hj:i:p:a:dD:Pn"
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
            "n")
                GLOBAL_USENINJA=1
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
            "?")
                panic "Invalid argument sent"
        esac
    done

}

# Parse the configuration file
confparse()
{
    GLOBAL_CMAKEVARS=
    # Parser variables
    parser_firstrun=1
    parser_secname=
    parser_subsec=
    parser_varname=
    parser_varval=
    parser_curline=0
    parser_file=$PWD/conf/nexnix.cfg
    # Compute the number of lines in the file
    parser_numlines=$(awk 'END { print NR }' $parser_file)
    # Loop through every line
    while :
    do
        # Have we reached th last line?
        if [ $parser_curline -eq $parser_numlines ]
        then
            # If so, break out
            break
        fi
        # Increment the current line
        parser_curline=$(($parser_curline+1))
        # Here is the main parser. Grab the current line first
        line="$(sed "$parser_curline!d" $parser_file)"
        # Check if this is a comment
        start=$(echo "$line" | awk '/^#/')
        if [ ! -z "$start" ]
        then
            continue
        fi
        # Shave whitespace
        wfree=$(echo "$line" | sed 's/[[:space:]]//g')
        # Check if this a section marker
        start=$(echo "$wfree" | awk '/^\[/')
        if [ ! -z "$start" ]
        then
            # Trim off whitespace
            line=$(echo "$line" | sed 's/[[:space:]]//g')
            # Check for a section end marker
            end=$(echo "$line" | awk '/]$/')
            if [ -z "$end" ]
            then
                # Syntax error!
                panic "Syntax error: section start must be followed by section end"
            fi
            # Get everything in between the brackets
            secname=$(echo "$line" | sed 's/^.//')
            secname=$(echo "$secname" | sed 's/.$//')
            # Is this an end marker?
            if [ "$secname" = "END" ]
            then
                # Check if we are even in a section
                if [ -z "$parser_secname" ]
                then
                    # Syntax error
                    panic "Syntax error: end section marker must come after section marker"
                fi
                # Check if this ends a section or subsection
                if [ -z "$parser_subsec" ]
                then
                    parser_secname=""
                else
                    parser_subsec=""
                fi
            else
                # Check if we have met the max depth
                if [ ! -z "$parser_subsec" ]
                then
                    panic "Syntax error: Maximum section depth is 2!"
                fi
                # We now must set the section
                # Is this a subsection?
                if [ ! -z "$parser_secname" ]
                then
                    parser_subsec="$secname"
                else
                    parser_secname="$secname"
                fi
            fi
        # Else this is a variable assignment
        else
            # Check if this is whitespace
            if [ -z "$line" ]
            then
                continue
            fi
            # Check for a colon
            iseq=$(echo "$line" | awk '/.:/')
            if [ -z "$iseq" ]
            then
                panic "Syntax error: Variable assignment must have colon"
            fi
            # Split it into two parts
            name=$(echo "$line" | awk -F':' '{print $1}')
            # Trim off leading whitespace
            name=$(echo "$name" | sed 's/[[:space:]]//g')
            val=$(echo "$line" | awk -F':' '{print $2}')
            # Ensure that both are present
            if [ -z "$name" ] || [ -z "$val" ]
            then
                panic "Syntax error: Variable requires name and value"
            fi
            # Shave off quotation marks
            val="$(echo "$val" | sed 's/\"//g')"
            # Prepend the section and subsection names
            if [ ! -z "$parser_subsec" ]
            then
                name="${parser_subsec}_${name}"
            fi
            name="${parser_secname}_${name}"
            # Shave trailing whitespace off of the name
            name=$(echo "$name" | sed 's/[[:space:]]//g')
            # Set the variable
            eval "$name=\$val"
            export $name
            val=$(eval "echo $val")
            GLOBAL_CMAKEVARS="${GLOBAL_CMAKEVARS} -D${name}=\"${val}\""
        fi
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
            # Parse it
            # Check for a colon
            iseq=$(echo "$def" | awk '/.:/')
            if [ -z "$iseq" ]
            then
                panic "Define error: Variable assignment must have a colon"
            fi
            # Split it into two parts
            name=$(echo "$def" | awk -F':' '{print $1}')
            val=$(echo "$def" | awk -F':' '{print $2}')
            # Ensure that both are present
            if [ -z "$name" ] || [ -z "$val" ]
            then
                panic "Define error: Variable requires name and value"
            fi
            # Shave off quotation marks
            val="$(echo "$val" | sed 's/\"//g')"
            # Shave trailing whitespace off of the name
            name=$(echo "$name" | sed 's/[[:space:]]//g')
            # Set the variable
            eval "$name=\$val"
            export $name
            val=$(eval "\$val")
            GLOBAL_CMAKEVARS="${GLOBAL_CMAKEVARS} -D\"${name}=\"${val}\"\""
        done
    fi
}

# Checks for data sanity
sanitycheck()
{
    # Check for a valid action
    if [ -z "$GLOBAL_ACTION" ]
    then
        panic "Action must be set"
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
        panic "Invalid action set"
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
            panic "Image must be sent"
        fi
    fi
    # Now check common stuff
    if [ ! -z "$GLOBAL_JOBCOUNT" ]
    then
        # Check if it is a number
        isnum=$(echo $GLOBAL_JOBCOUNT | awk '$0 ~ /[0-9]/')
        if [ -z "$isnum" ]
        then
            panic "Job count must be a number"
        fi
    fi
    # Check the prefix
    if [ -z "$GLOBAL_PREFIX" ]
    then
        panic "Prefix must be set"
    fi
    # Check that is absolute
    isabs=$(echo "$GLOBAL_PREFIX" | awk '$0 ~ /^\// { print $0 }')
    if [ -z "$isabs" ]
    then
        panic "prefix must be absolute"
    fi
    # Else, check the architecture
    if [ -z "$GLOBAL_ARCH" ] || [ -z "$GLOBAL_ARCHS" ]
    then
        panic "Architecture must be set"
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
        panic "Architecture invalid"
    fi
    # Split it up
    export GLOBAL_MACH=$(echo "$GLOBAL_ARCH" | awk -F'-' '{ print $1 }')
    GLOBAL_CMAKEVARS="${GLOBAL_CMAKEVARS} -DGLOBAL_MACH=\"${GLOBAL_MACH}\""
    export GLOBAL_BOARD=$(echo "$GLOBAL_ARCH" | awk -F'-' '{ print $2 }')
    GLOBAL_CMAKEVARS="${GLOBAL_CMAKEVARS} -DGLOBAL_BOARD=\"${GLOBAL_BOARD}\""
}

# Builds the system
build()
{
    # Install the headers first
    mkdir -p $GLOBAL_PREFIX/usr/include
    cp -r $PWD/usr/include/* $GLOBAL_PREFIX/usr/include
    if [ ! -d "build-$GLOBAL_ARCH" ]
    then
        mkdir build-$GLOBAL_ARCH
    fi
    if [ $GLOBAL_USENINJA -eq 1 ]
    then
        # Check for ninja
        if ! command -v ninja > /dev/null
        then
            panic "Ninja not found"
        fi
        CMAKEGEN="Ninja"
        BUILDPROG=ninja
    else
        CMAKEGEN="Unix Makefiles"
        BUILDPROG=make
    fi

    # First build neximg
    if [ ! -d build-neximg ]
    then
        mkdir build-neximg
    fi
    cd build-neximg
    cmake ../neximg -DCMAKE_INSTALL_PREFIX="$GLOBAL_PREFIX" -G$CMAKEGEN -DGLOBAL_DEBUG="$GLOBAL_DEBUG" \
        -DGLOBAL_PROFILE="$GLOBAL_PROFILE"
    checkerror $? "prepare failed"
    $BUILDPROG -j8
    checkerror $? "build failed"
    $BUILDPROG install -j8
    checkerror $? "install failed"
    cd ..
    # Build the rest of the system
    cd build-$GLOBAL_ARCH
    eval cmake .. -DCMAKE_INSTALL_PREFIX="$GLOBAL_PREFIX" -G$CMAKEGEN $GLOBAL_CMAKEVARS
    checkerror $? "prepare failed"
    $BUILDPROG -j$GLOBAL_JOBCOUNT
    checkerror $? "build failed"
    $BUILDPROG install -j$GLOBAL_JOBCOUNT
    checkerror $? "install failed"
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
    # Now we need to read the configuration file
    confparse
    # Parse the arguments again to override the configuration file
    argparse
    # Now we must parse user specified settings overrides
    urideparse
    # Check that it is all valid
    sanitycheck
    # Set debug and profiling values
    GLOBAL_CMAKEVARS="${GLOBAL_CMAKEVARS} -DGLOBAL_DEBUG=\"${GLOBAL_DEBUG}\" -DGLOBAL_PROFILE=\"${GLOBAL_PROFILE}\""
    # Run based on action now
    if [ "$GLOBAL_ACTION" = "dep" ]
    then
        ./dep/builddep.sh
    elif [ "$GLOBAL_ACTION" = "image" ]
    then
        build
    elif [ "$GLOBAL_ACTION" = "build" ]
    then
        build
    elif [ "$GLOBAL_ACTION" = "clean" ]
    then
        rm -rf build-*
    fi
}

main "$@"
