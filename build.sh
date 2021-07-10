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
                isabs=$(echo $GLOBAL_PREFIX | awk '$0 ~ /^\// { print $0 }')
                if [ -z "$isabs" ]
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
                ;;
            "?")
                panic "Invalid argument sent"
        esac
    done

}

# Parse the configuration file
confparse()
{
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
        # Check if this a section marker
        start=$(echo "$line" | awk '/^\[/')
        if [ ! -z "$start" ]
        then
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
                panic "Syntax error: Variable assignment must have equals colon"
            fi
            # Split it into two parts
            name=$(echo "$line" | awk -F':' '{print $1}')
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
        done
    fi
}

# Main script function. It controls everything else
main()
{
    # Set LC_ALL to C for regex
    export LC_ALL=C
    # Grab the arguments passed to us
    GLOBAL_ARGS="$@"
    # Now we need to parse these arguments
    argparse
    # Now we need to read the configuration file
    confparse
    # Now we must parse user specified settings overrides
    urideparse

    # Now we can finally start to build!
}

main "$@"
