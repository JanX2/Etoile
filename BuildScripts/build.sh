#!/bin/sh

SCRIPT_DIR=$PWD
PROFILE_SCRIPT=testbuild.config

# Process script options

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
      echo "                            process (default: \$PWD/defaultbuild.config)"
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
    --build-profile)
      PROFILE_SCRIPT=$optionarg;; 
    --build-dir)
      BUILD_DIR=$optionarg;;
    --prefix)
      PREFIX_DIR=$optionarg;; 
    --version)
      ETOILE_VERSION=$optionarg;; 
    *)
      ;;
  esac
  shift
done

# Load the build profile

. $SCRIPT_DIR/$PROFILE_SCRIPT

# Create a build directory if none exists

if [ ! -d $BUILD_DIR ]; then
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

if [ "$LLVM_VERSION" = "trunk" ]; then

	echo "WARNING: Installing LLVM from svn trunk is not supported yet"

elif [ -n "$LLVM_VERSION" -a ! -d llvm-$LLVMVERSION  ]; then

	wget -nc http://llvm.org/releases/${LLVM_VERSION}/llvm-${LLVM_VERSION}.tar.gz
	tar -xzf llvm-{LLVM_VERSION}.tar.gz
fi

if [ -n "$LLVM_VERSION" ]; then

	cd llvm-${LLVM_VERSION}
	./${LLVM_CONFIGURE} && $MAKE_BUILD && $MAKE_INSTALL
	cd ..
fi

# Download, build and Install GNUstep

. $SCRIPT_DIR/build-gnustep.sh

exit

# Download, build and install Etoile

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

