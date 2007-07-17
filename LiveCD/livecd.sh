#!/bin/sh

# NOTE: List of customization variables is located after script options processing

SCRIPT_DEBUG=yes

# Default values for script stages
PREPARE=no
BUILD=no
SHRINK=no
GENERATE=no
EDIT=no
TEST=no
CLEANUP=no

#
# Script Options Processing
#

while test $# != 0
do
  option=
  case $1 in
    --help | -h)
      echo "$0: Script to build, test and generate Etoile LiveCD"
      echo "Do nothing by default, you must specify at least one option like --livecd"
      echo
      echo "Options:"
      echo "      --help      - Print help"
      echo "  -l, --livecd    - Create Etoile LiveCD iso from scratch by taking care of all"
      echo "                    steps. Shortcut to livecd.sh --prepare -- build --cleanup "
      echo "                   --shrink --generate"
      echo
      echo "  -p, --prepare   - Download Ubuntu LiveCD, mount and extract to be ready for "
      echo "                    customization"
      echo "  -b, --build     - Build and set up Etoile Environment by downloading and "
      echo "                    compiling all dependencies"
      echo "  -s, --shrink    - Reduce LiveCD size by removing as many packages as possible, "
      echo "                    mostly GNOME stuff but many unrelated elements too."
      echo "  -g, --generate  - Generate Etoile LiveCD iso by compressing customized LiveCD "
      echo "                    directory"
      echo
      echo "  -e, --edit      - Test and customize LiveCD running as a sandboxed environment"
      echo "                    in shell. Done by calling chroot on LiveCD directory"
      echo "  -t, --test      - Test LiveCD environment. Done by calling --edit and "
      echo "                    launching GDM. Run on DISPLAY=:0.9 by default"
      echo "  -c, --cleanup   - Clean up LiveCD environment of every testing specific "
      echo "                    settings and user preferences/defaults"
      echo
      exit 0
      ;;
    --livecd | -l)
      PREPARE=yes; BUILD=yes; CLEANUP=yes; SHRINK=yes; GENERATE=yes;;
    --prepare | -p)
      PREPARE=yes;;
    --build | -b)
      BUILD=yes;;
    --shrink | -s)
      SHRINK=yes;;
    --generate | -g)
      GENERATE=yes;;
    --edit | -e)
      EDIT=yes;;
    --test | -t)
      TEST=yes;;
    --cleanup | -c)
      CLEANUP=yes;;
    --*=*)
      option=`expr "x$1" : 'x\([^=]*\)='`
      optionarg=`expr "x$1" : 'x[^=]*=\(.*\)'`
      ;;
    *)
      ;;
  esac

  case $option in
    --livcd-dir)
      LIVECD_DIR=$optionarg;;
    --ubuntu-image)
      UBUNTU_IMAGE=$optionarg;; 
    --etoile-livecd-name)
      ETOILE_LIVECD_NAME=$optionarg;; 
    --etoile-image-name)
      ETOILE_IMAGE_NAME=$optionarg;; 
    --etoile-user-name)
      ETOILE_USER_NAME=$optionarg;; 
    --etoile-user-password)
      ETOILE_USER_PASSWORD=$optionarg;; 
    *)
      ;;
  esac
  shift
done

# Uncomment to test if checkVar handles properly variable already set
#LIVECD_DIR=/bla

# Check variable has been set by the user or through scripts options, if not 
# set to default value passed as second parameter, finally export it to be 
# available in subscripts.
checkVar () 
{
	# Double substitution $1 -> $varname -> value
	# The clean way to express it would be $($1)
	value="$(eval echo '$'$1)"; 
	#echo $value
	if [ -z $value ]; then
		# Single quotes are critical to prevent $2 interpretation by eval
		# otherwise this line fails on any strings which includes spaces
		eval $1='$2'; 
	else
		echo "$1 is already set to $value";
	fi
	export $1;

	if [ $SCRIPT_DEBUG = yes ]; then
		value="$(eval echo '$'$1)";
		echo "Exported $1 = $value";
	fi
}

#
# Script Customization Variables
#

echo

# For example ~/live
checkVar LIVECD_DIR "$PWD/live";

# For example ~/Desktop/ubuntu-6.06.1-desktop-i386.iso
checkVar UBUNTU_IMAGE "$LIVECD_DIR/ubuntu-7.04-desktop-i386.iso"
#checkVar(UBUNTU_IMAGE_NAME ubuntu-7.04-desktop-i386.iso)

checkVar ETOILE_LIVECD_NAME "Etoile LiveCD 0.2"
checkVar ETOILE_IMAGE_NAME "etoile.iso"

checkVar ETOILE_USER_NAME "guest"
checkVar ETOILE_USER_PASSWORD "guest"

checkVar SUBSCRIPT_DIR "./Subscripts"

#
# Script Action
#

if [ $SCRIPT_DEBUG = yes ]; then
	echo
	echo "PREPARE: $PREPARE, BUILD: $BUILD, SHRINK: $SHRINK, CLEANUP = $CLEANUP, GENERATE: $GENERATE"
	echo "EDIT: $EDIT"
	echo "TEST: $TEST"
	echo
fi

if [ $PREPARE = yes ]; then
	$SUBSCRIPT_DIR/livecd-prepare.sh;
fi

if [ $EDIT = yes ]; then
	$SUBSCRIPT_DIR/livecd-edit.sh;
fi

if [ $BUILD = yes ]; then
	$SUBSCRIPT_DIR/livecd-build.sh;
fi

if [ $SHRINK = yes ]; then
	$SUBSCRIPT_DIR/livecd-build.sh;
fi

if [ $CLEANUP = yes ]; then
	$SUBSCRIPT_DIR/livecd-cleanup.sh;
fi

if [ $GENERATE = yes ]; then
	$SUBSCRIPT_DIR/livecd-generate.sh;
fi

if [ $TEST = yes ]; then
	$SUBSCRIPT_DIR/livecd-test.sh;
fi

