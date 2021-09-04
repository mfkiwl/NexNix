#! /bin/bash
# osconfgen.sh - generates a NexNix configuration
# SPDX-License-Identifier: ISC

prefix=
conffile=
imagepath=
outputdir=
user=

# Prints out an error and then exits
panic()
{
    echo "$(basename $0): $1"
    exit 1
}

# Checks for an error, and if one occurred, panics

checkerror()
{
    if [ "$1" != "0" ]
    then
        panic "$2"
    fi
}

main()
{
    # First, parse the arguments
    arglist="p:i:c:o:u:"
    while getopts $arglist arg $@ > /dev/null 2>&1; do
        case ${arg} in
            "p")
                # Validate that it is absolute and exists
                prefix=$OPTARG
                if [ ! -d "$prefix" ]
                then
                    panic "prefix doesn't exist"
                fi
                isabs=$(echo "$prefix" | awk '$0 ~ /^\// { print $0 }')
                if [ -z "$isabs" ]
                then
                    panic "prefix must be absolute"
                fi
            ;;
            "i")
                imagepath=$PWD/$OPTARG
                if [ ! -d "$imagepath" ]
                then
                    mkdir -p $imagepath
                fi
                isabs=$(echo "$imagepath" | awk '$0 ~ /^\// { print $0 }')
                if [ -z "$isabs" ]
                then
                    panic "image path must be absolute"
                fi
            ;;
            "u")
                user=$OPTARG
            ;;
            "c")
                conffile=$OPTARG
                if [ ! -f "$conffile" ]
                then
                    panic "configuration file doesn't exist"
                fi
            ;;
            "o")
                outputdir=$PWD/$OPTARG
                if [ ! -d "$outputdir" ]
                then
                    mkdir -p $outputdir
                fi
            ;;
            "?")
                panic "invalid argument passed"
        esac
    done
    # Check that everything was passed
    if [ -z "$conffile" ]
    then
        panic "configuration file not specified"
    fi
    if [ -z "$outputdir" ]
    then
        panic "output directory not specified"
    fi
    if [ -z "$user" ]
    then
        panic "user not specified"
    fi
    if [ -z "$imagepath" ]
    then
        panic "image path not specified"
    fi
    if [ -z "$prefix" ]
    then
        panic "prefix not specified"
    fi
    # Remove the output directory
    rm -rf $outputdir
    # Now we need to read the configuration file and perform the actions specified therein
    numlines=$(awk 'END { print NR }' $conffile)
    curline=1
    while [ ! $curline -gt $numlines ]
    do
        # Get the current line text
        line=$(sed "$curline!d" $conffile)
        # Check if this is a comment
        iscomment=$(echo "$line" | awk '/^#/ { print $0 }')
        if [ ! -z "$iscomment" ]
        then
            curline=$((curline+1))
            continue
        fi
        # Check if this is a whitespace line
        wspacefree=$(echo "$line" | sed "s/[[:space:]]//g")
        if [ -z "$wspacefree" ]
        then
            curline=$((curline+1))
            continue
        fi
        for field in $line
        do
            # Check if this is an action
            if [ -z "$action" ]
            then
                action=$field
                continue
            fi
            # Now find which action this is
            # The way this checks what arguments this is feels hacky, but it works
            # TODO: Find a better way of doing this
            if [ "$action" = "file" ]
            then
                # Check what parameter this is
                if [ -z "$srcfile" ]
                then
                    srcfile="${prefix}/${field}"
                    if [ ! -f "$srcfile" ]
                    then
                        panic "$conffile: $srcfile doesn't exist"
                    fi
                elif [ -z "$destfile" ]
                then
                    destfile=${outputdir}/${field}
                elif [ -z "$prefile" ]
                then
                    prefile=${outputdir}/${field}
                else
                    panic "$conffile: too many arguments to image action"
                fi
            elif [ "$action" = "image" ]
            then
                if [ -z "$imgsize" ]
                then
                    # Check this this is numeric
                    isnum=$(echo "$field" | awk '/^[:digit:]/ { print $0 }')
                    if [ ! -z "$isnum" ]
                    then
                        panic "$conffile: image size must be a number"
                    fi
                    imgsize=$field
                elif [ -z "$imgname" ]
                then
                    imgname=${imagepath}/${field}
                elif [ -z "$imgtype" ]
                then
                    imgtype=$field
                else
                    parts="${parts}-p${field} "
                fi
            elif [ "$action" = "mbrwrite" ]
            then
                if [ -z "$mbrpath" ]
                then
                    mbrpath="${prefix}/${field}"
                    if [ ! -f $mbrpath ]
                    then
                        panic "$conffile: ${field} not found"
                    fi
                elif [ -z "$imgname" ]
                then
                    imgname="${imagepath}/${field}"
                    if [ ! -f $imgname ]
                    then
                        panic "$conffile: ${field} not found"
                    fi
                elif [ -z "$vbrpath" ]
                then
                    vbrpath="${prefix}/${field}"
                    if [ ! -f $vbrpath ]
                    then
                        panic "$conffile: ${field} not found"
                    fi
                elif [ -z "$vbrbase" ]
                then
                    # Check if this is numeric
                    isnum=$(echo "$field" | awk '/^[:digit:]/ { print $0 }')
                    if [ ! -z "$isnum" ]
                    then
                        panic "$conffile: VBR base must be a number"
                    fi
                    vbrbase=$field
                else
                    panic "$conffile: too many arguments to mbrwrite action"
                fi
            elif [ "$action" = "mbrwrap" ]
            then
                if [ -z "$imgname" ]
                then
                    imgname="${imagepath}/${field}"
                    if [ ! -f $imgname ]
                    then
                        panic "$conffile: ${field} not found"
                    fi
                elif [ -z "$espbase" ]
                then
                    # Check if this is numeric
                    isnum=$(echo "$field" | awk '/^[:digit:]/ { print $0 }')
                    if [ ! -z "$isnum" ]
                    then
                        panic "$conffile: ESP base must be a number"
                    fi
                    espbase=$field
                elif [ -z "$espend" ]
                then
                    # Check if this is numeric
                    isnum=$(echo "$field" | awk '/^[:digit:]/ { print $0 }')
                    if [ ! -z "$isnum" ]
                    then
                        panic "$conffile: ESP end must be a number"
                    fi
                    espend=$field
                else
                    panic "$conffile: too many arguments to mbrwrap action"
                fi
            else
                panic "$conffile: unrecognized action specified"
            fi
        done
        if [ "$action" = "file" ]
        then
            # Create a hard link between the files
            mkdir -p $(dirname $destfile)
            if [ ! -z "$prefile" ]
            then
                cat $prefile $srcfile > $destfile
            else
                link $srcfile $destfile
            fi
            chown $user $destfile
            srcfile=
            destfile=
            prefile=
        elif [ "$action" = "image" ]
        then
            # Run image.sh
            ./scripts/image.sh -s$imgsize -i$imgname -d$outputdir -t$imgtype -u$user $parts
            checkerror $? "unable to create disk image"
            imgsize=
            imgname=
            imgtype=
            parts=
        elif [ "$action" = "mbrwrite" ]
        then
            # Run mbrwrite
            ./utilsbin/mbrwrite $mbrpath $imgname $vbrpath $vbrbase
            checkerror $? "unable to write out MBR"
            mbrpath=
            imgname=
            vbrpath=
            vbrbase=
        elif [ "$action" = "mbrwrap" ]
        then
            # Run mbrwrap
            ./utilsbin/mbrwrap $imgname $espbase $espend
            checkerror $? "unable to wrap up ESP"
            imgname=
            espbase=
            espend=
        fi
        action=
        curline=$((curline+1))
    done
    chown $user -R $outputdir
    chown $user -R $imagepath
}

main "$@"
