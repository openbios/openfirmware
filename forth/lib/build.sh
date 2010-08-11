#!/bin/sh
# Script to invoke the FirmWorks build facility.
# Usage:  build [-c|d|h|q|t|v] [target-name]
#
# This script automates the process of setting the BP and HOSTDIR
# environment variables and parses the option flags [-c|d|h|q|t|v].

# In order to run the build facility without this script:
# Set the BP environment variable to the firmware root directory
# Set the HOSTDIR environment variable to ${BP}/cpu/<cpuname>/<osname>,
#   e.g. ${BP}/cpu/arm/Linux
# Execute:
#    ${HOSTDIR}/forth ${HOSTDIR}/../native.dic
# At the "ok" prompt, type:
#    build <target-name>
# or
#    tag <target-name>

# Set BP by searching upward for the firmware root directory
test -n "$BP" || {
    dir=`pwd`
    {
        until [ -d ofw ]; do
            if [ `pwd` = / ] ; then
                echo Can\'t find firmware root directory
                exit
            fi
            cd ..
        done
        BP=`pwd`
        export BP
    }
    cd $dir
}

# Set HOSTDIR according to the value of BP and the host system
test -n "$HOSTDIR" || {
    OSNAME=`uname`
    MACHNAME=`uname -m`
    case ${MACHNAME} in
        sun4c) CPUNAME=sparc ;;
        sun4u) CPUNAME=sparc ;;
        ppc)   CPUNAME=powerpc ;;
        i386)  CPUNAME=x86 ;;
        i586)  CPUNAME=x86 ;;
	i686)  CPUNAME=x86 ;;
        mips)  CPUNAME=mips ;;
        arm)   CPUNAME=arm ;;
        arm32) CPUNAME=arm ;;
        sun3)  CPUNAME=m68k ;;
        *)     CPUNAME=${MACHNAME} ;;
    esac
}
export HOSTDIR=${BP}/cpu/${CPUNAME}/${OSNAME}

command=build

# Parse option flags
case $1 in
    -c) mode=clean;	shift ;;
    -d) mode=prolix;	shift ;;
    -q) mode=quiet;	shift ;;
    -t) command=tag;	shift ;;
    -v) mode=verbose;	shift ;;
    -h)
  echo "Usage:  build [-c|d|h|q|t|v] [target-name]"
  echo "    With no flags, shows commands that are executed to rebuild targets"
  echo "    -c: clean - ignores log files"
  echo "    -d: debug - shows the names of source files as they are checked"
  echo "    -h: display this helpful message"
  echo "    -q: quiet - suppresses normal showing of targets being rebuilt"
  echo "    -t: tag - used after a successful build, sends to stdout a list"
  echo "        of all the source files that were used in that build"
  echo "    -v: verbose - shows progress of dependency checking"
  echo ""
  echo "    Target-name may, but need not, have an extension"
  echo ""
  echo "    If target-name is omitted, the builder is executed interactively"
        exit 0;;
    *)  unset mode ;;
esac

if [ `basename $0` = forth ]; then
    mode=".copyright interact"
    if [ $# -eq 0 ]; then
	exec ${FORTH:-${HOSTDIR}/forth} ${NATIVE:-${HOSTDIR}/../build/builder.dic} \
	    -s "$mode $command $*"
    elif [ `basename $1` != `basename $1 .dic`.dic ]; then
	exec ${FORTH:-${HOSTDIR}/forth} ${NATIVE:-${HOSTDIR}/../build/builder.dic} $*
    else
	exec ${FORTH:-${HOSTDIR}/forth} $*
    fi
elif [ $# -eq 0 ]; then		# Ensure the "target-name" argument is present
    echo "No target name specified; executing builder in interactive mode"
    mode=interact
fi

${FORTH:-${HOSTDIR}/forth} ${NATIVE:-${HOSTDIR}/../build/builder.dic} \
	-s "$mode $command $*"
