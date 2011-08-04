#!/bin/bash

# Determine script path and directory
cd $(dirname "${0}") 
SCRIPT_DIR=$(pwd -L)
cd - 

PROFILE_SCRIPT=$PWD/testbuild.config

# Process script options second (so they can override build profile)

while test $# != 0
do
  option=
  case $1 in
    --help | -h)
      echo
      echo "`basename $0` - Script to build, test and install the Etoile environment "
      echo
      echo "Note: this script will append a new line to ~/.bashrc"
      echo
      echo "Requirements: "
      echo
      echo "  wget, GNU make and sudo access (sudo access is required by the default profile)"
      echo
      echo "Actions:"
      echo
      echo "  --help                   - Print help"
      echo
      echo "Options:"
      echo "Type --option-name=value to set an option and quote the value when it contains "
      echo "spaces."
      echo
      echo "  --profile               - Path to the build profile that describe the build "
      echo "                            process (default: \$PWD/testbuild.config)"
      echo "  --build-dir             - Name of the directory inside which the build will "
      echo "                            happen (default: \$PWD/build)"
      echo "  --prefix                - Path where GNUstep and Etoile will be installed"
      echo "                            (default:  /)"
      echo "  --version               - Version of the Etoile environment to check out and "
      echo "                            and build, either 'stable' or 'trunk'. The related "
      echo "                            repository code will be checked out in "
      echo "                            $build-dir/Etoile"
      echo "                            (default: trunk)"
      echo
      exit 0
      ;;
    --*=*)
      option=`expr "x$1" : 'x\([^=]*\)='`
      optionarg=`expr "x$1" : 'x[^=]*=\(.*\)'`
      ;;
    *)
      ;;
  esac

  case $option in
    --profile)
      PROFILE_SCRIPT_override=$optionarg;; 
    --build-dir)
      BUILD_DIR_override=$optionarg;;
    --prefix)
      PREFIX_DIR_override=$optionarg;; 
    --version)
      ETOILE_VERSION_override=$optionarg;; 
    *)
      ;;
  esac
  shift
done

PROFILE_SCRIPT=${PROFILE_SCRIPT:-"$PWD/defaultbuild.config"}
PROFILE_SCRIPT=${PROFILE_SCRIPT_override:-"$PROFILE_SCRIPT"}
. $PROFILE_SCRIPT

# Define variables if not defined on command line or in build profile
BUILD_DIR=${BUILD_DIR:-"$PWD/build"}
BUILD_DIR=${BUILD_DIR_override:-"$BUILD_DIR"}

PREFIX_DIR=${PREFIX_DIR:-"/"}
PREFIX_DIR=${PREFIX_DIR_override:-"$PREFIX_DIR"}

ETOILE_VERSION=${ETOILE_VERSION:-"trunk"}
ETOILE_VERSION=${ETOILE_VERSION_override:-"$ETOILE_VERSION"}

echo "PROFILE_SCRIPT = $PROFILE_SCRIPT"
echo "BUILD_DIR = $BUILD_DIR"
echo "PREFIX_DIR = $PREFIX_DIR"
echo "ETOILE_VERSION = $ETOILE_VERSION"

export BUILD_DIR
export PREFIX_DIR

# Create a build directory if none exists

if [ ! -d "$BUILD_DIR" ]; then
	mkdir $BUILD_DIR
else
	echo "Found existing build directory"
fi

cd $BUILD_DIR

# Create the log directory and subdirectory for the new build

if [ ! -d $LOG_BASE_DIR ]; then
	mkdir $LOG_BASE_DIR
fi

mkdir $LOG_DIR

# Install Etoile and GNUstep dependencies 

#. $SCRIPT_DIR/$DEPENDENCY_SCRIPT

# Download, build and install LLVM

export LOG_NAME=llvm-build

export LLVM_SOURCE_DIR=$BUILD_DIR/llvm-$LLVM_VERSION
export LLVM_INSTALL_DIR=$PREFIX_DIR/llvm-install-$LLVM_VERSION

if [ "$LLVM_VERSION" = "trunk" ]; then
	if [ ! -d $LLVM_SOURCE_DIR ] 
	then
		echo "Fetching LLVM trunk using a GIT mirror at $LLVM_URL_GIT"
		git clone $LLVM_URL_GIT $LLVM_SOURCE_DIR
	else
		echo "Updating LLVM trunk using a GIT mirror at $LLVM_URL_GIT"
		git pull $LLVM_SOURCE_DIR
	fi
elif [ -n "$LLVM_VERSION" -a ! -d $LLVM_SOURCE_DIR ]; then
	echo "Fetching LLVM $LLVM_VERSION from LLVM release server"
	wget -nc http://llvm.org/releases/${LLVM_VERSION}/llvm-${LLVM_VERSION}.tar.gz
	tar -xzf llvm-{LLVM_VERSION}.tar.gz
	echo "Fetching Clang $LLVM_VERSION from LLVM release server"
	wget -nc  http://llvm.org/releases/${LLVM_VERSION}/clang-${LLVM_VERSION}.tar.gz
	tar -xzf clang-{LLVM_VERSION}.tar.gz
fi

if [ -n "$LLVM_VERSION" ]; then

	cd $LLVM_SOURCE_DIR
	./${LLVM_CONFIGURE} --prefix=$LLVM_INSTALL_DIR && $MAKE_BUILD && $MAKE_INSTALL
	cd ..
	# Put LLVM in the path
	export PATH=$LLVM_INSTALL_DIR/bin:$PATH
fi

# Download, build and Install GNUstep
echo "Building GNUstep core libraries"
. $SCRIPT_DIR/build-gnustep.sh

exit

# Download, build and install Etoile
echo "Building Etoile"
export LOG_NAME=etoile-build

if [ "$ETOILE_VERSION" = "stable" ]; then
	ETOILE_REP_PATH=stable
elif [ "$ETOILE_VERSION" = "trunk" ]; then
	ETOILE_REP_PATH=trunk/Etoile
fi

if [ -n "$ETOILE_VERSION" ]; then

	${SVN_ACCESS}svn.gna.org/svn/etoile/${ETOILE_REP_PATH} etoile-${ETOILE_VERSION}

	cd etoile-${ETOILE_VERSION}
	$MAKE_BUILD && $MAKE_INSTALL

else

	echo 
	echo "--> Finished... Warning: Etoile has not been built as requested!"
	echo
	exit

fi

# For now, setup is pretty much useless and kinda broken
#./setup.sh

echo
echo "--> Finished Etoile build :-)"
echo
#echo "You now need to log out and choose Etoile session in GDM, then log in "
#echo "to start Etoile."
#echo

# TODO: Make possible to skip setup.sh and run it later manually
#echo
#echo "Installation of Etoile is almost finished, you now need to run setup.sh "
#echo "script by yourself to have a usable environment."
#echo
#echo " -- The script path is $BUILD_DIR/Etoile/setup.sh -- "
#echo

