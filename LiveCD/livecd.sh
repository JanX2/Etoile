#!/bin/sh

# NOTE: List of customization variables is located after script options processing

# Default values for script stages
PREPARE=yes
BUILD=yes
GENERATE=yes
EDIT=yes
TEST=no
CLEANUP=yes

#
# Script Options Processing
#

while test $# != 0
do
  option=
  case $1 in
    --help | -h)
      echo "$0: Script to build, test and generate Etoile LiveCD"
      echo "Options:"
      echo "  --help	  - Print help"
      echo "  --prepare	  - Download Ubuntu LiveCD, mount and extract to be ready for customization"
      echo "  --build     - Build and set up Etoile Environment by downloading and compiling all dependencies"
      echo "  --generate  - Generate Etoile LiveCD iso by compressing customized LiveCD directory"
      echo
      echo "  --edit      - Test and customize LiveCD running as a sandboxed environment in shell. Done by calling chroot on LiveCD directory"
      echo "  --test      - Test LiveCD environment. Done by calling --edit and launching GDM"
      echo "  --cleanup   - Clean up LiveCD environment of every testing specific settings and user preferences/defaults"
      exit 0
      ;;
    --prepare | -p)
      PREPARE=yes;;
    --build | -b)
      BUILD=yes;;
    --generate | -g)
      BUILD=yes;;
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

# Check variable has been set by the user or through scripts options, if not 
# set to default value passed as second parameter, finally export it to be 
# available in subscripts.
checkVar () 
{
	if [ $1 ]; then
		$1=$2
	fi
	export $1
}

#
# Script Customization Variables
#

# For example ~/live
checkVar(LIVECD_DIR, $PWD/live)

# For example ~/Desktop/ubuntu-6.06.1-desktop-i386.iso
checkVar(UBUNTU_IMAGE, $LIVECD_DIR/ubuntu-7.04-desktop-i386.iso)
#checkVar(UBUNTU_IMAGE_NAME, ubuntu-7.04-desktop-i386.iso)

checkVar(ETOILE_LIVECD_NAME, "Etoile LiveCD 0.2")
checkVar(ETOILE_IMAGE_NAME, etoile.iso)

checkVar(ETOILE_USER_NAME, guest)
checkVar(ETOILE_USER_PASSWORD, guest)

checkVar(SUBSCRIPT_DIR, ./Subscripts)

#
# Script Action
#

if [ PREPARE = yes ]; then
	$SUBSCRIPT_DIR/livecd-prepare.sh
fi

if [ EDIT = yes ]; then
	$SUBSCRIPT_DIR/livecd-edit.sh
fi

if [ BUILD = yes ]; then
	$SUBSCRIPT_DIR/livecd-build.sh
fi

if [ CLEANUP = yes ]; then
	$SUBSCRIPT_DIR/livecd-cleanup.sh
fi

if [ GENERATE = yes ]; then
	$SUBSCRIPT_DIR/livecd-generate.sh
fi

if [ TEST = yes ]; then
	$SUBSCRIPT_DIR/livecd-test.sh
fi

