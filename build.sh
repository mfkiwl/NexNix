#! /bin/sh
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


help()
{
    # Print out help info
    cat <<end
$(basename $0) - builds a distribution of NexNix
$(basename $0) is a powerful script which is used to build the NexNix operating system
It uses the file conf/nexnix.conf, while contains all configuration data in realtion to NexNix, using an INI like format
See docs/conf.md for more info on it
Below are valid options which can be passed to $(basename $0)
    -h - shows this help screen
    -A ACTION - tells the scripts what it needs to do. These include:
        "build" - builds the system and installs in in the prefix directory
        "clean" - removes all intermediate files / folders
        "dist" - builds a tarball of the source files
        "image" - builds the system, and then creates a disk image
        "dump" - dumps all valid architectures
    This option is required
    -j JOBS - specifies how many concurrent jobs to use. If the nproc(1) command is available, then this is the default, else, 1 is the default
    -i IMAGE - specifies the disk image to output to. Required for action "image", else unused
    -p PREFIX - specifies directory to install everything into. Required for actions "build" and "image", unused for everything else
    -a ARCH - specifies the target architecture to build for. Required for actions "build" and "image"
    -d DISKTYPE - specifies the partition format for the disk. It can be either "mbr" or "gpt". Note that architectural\
restrictions may constraint this option
    -D "PARAMS" - contains configuration overrides. This allows for users to override the default configuration in nexnix.conf
end
}
# Main variables
GLOBAL_ARGS=
GLOBAL_ACTION=
GLOBAL_ACTIONS="build clean image dist dump"
GLOBAL_JOBCOUNT=
GLOBAL_PREFIX=
GLOBAL_IMAGE=
GLOBAL_ARCH=
GLOBAL_DISKTYPE=
GLOBAL_DISKTYPES="mbr gpt"
GLOBAL_DEFINES=

# Parses data in the GLOBAL_ARGS variable
argparse()
{
    arglist="A:hj:i:p:a:d:D:"
    # Start the loop
    while getopts $arglist arg $GLOBAL_ARGS > /dev/null 2> /dev/null; do
        case ${arg} in
            "h")
                # If -h was passed, print out the help screen
                help
                ;;
            "A")
                # Check if it is a valid action
                for action in $GLOBAL_ACTIONS
                do
                    # Check it now
                    if [ "$OPTARG" = "$action" ]
                    then
                        GLOBAL_ACTION="$OPTARG"
                    fi
                done
                # Check if we found the action
                if [ -z "$GLOBAL_ACTION" ]
                then
                    panic "Invalid action set"
                fi
                ;;
            "j")
                # Set the job count
                GLOBAL_JOBCOUNT="$OPTARG"
                ;;
            "i")
                # Grab the image
                GLOBAL_IMAGE="$OPTARG"
                ;;
            "p")
                # Grab the prefix directory
                GLOBAL_PREFIX="$OPTARG"
                # Check that it is valid
                if [ -d "$GLOBAL_PREFIX" ]
                then
                    message "Prefix already exists! Delete? [y/n]"
                    read REPLY;
                    # Check the response
                    if [ "$REPLY" = "y" ]
                    then
                        rm -rf $GLOBAL_PREFIX
                    else
                        exit 1
                    fi
                fi
                # Check if the prefix is absolute
                isabs=$(echo $GLOBAL_PREFIX | grep -o '^/')
                if [ "$isabs" != '/' ]
                then
                    panic "prefix must be an absolute path"
                fi
                ;;
            "a")
                GLOBAL_ARCH="$OPTARG"
                ;;
            "d")
                # Check its validity
                for type in $GLOBAL_DISKTYPES
                do
                    if [ "$type" = "$OPTARG" ]
                    then
                        GLOBAL_DISKTYPE="$OPTARG"
                    fi
                done
                # Check if we found a disk type
                if [ -z "$GLOBAL_DISKTYPE" ]
                then
                    panic "Invalid disk type set"
                fi
                ;;
            "D")
                # Just grab it
                GLOBAL_DEFINES="$OPTARG"
                echo "$GLOBAL_DEFINES"
                ;;
            "?")
                panic "Invalid argument sent"
        esac
    done

}

# Parse the configuration file
confparse()
{
    echo "test"
}

# Main script function. It controls everything else
main()
{
    # Grab the arguments passed to us
    GLOBAL_ARGS="$@"
    # Now we need to parse these arguments
    argparse
    # Now we need to read the configuration file
    confparse
}

main "$@"
