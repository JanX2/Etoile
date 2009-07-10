#!/bin/sh

# --build

# Initialize option variables with default values

BUILD_DIR=$PWD/build
PREFIX_DIR=/
ETOILE_VERSION=stable

# Process script options

while test $# != 0
do
  option=
  case $1 in
    --help | -h)
      echo
      echo "`basename $0` - Script to build and install the Etoile environment "
      echo
      echo "Note: this script will append a new line to ~/.bashrc"
      echo
      echo "Requirements: "
      echo
      echo "  wget, GNU make and sudo access"
      echo
      echo "Actions:"
      echo
      echo "  --help                   - Print help"
      echo
      echo "Options:"
      echo "Type --option-name=value to set an option and quote the value when it contains "
      echo "spaces."
      echo
      echo "  --build-dir             - Name of the directory inside which the build will "
      echo "                            happen (default: \$PWD/build)"
      echo "  --prefix                - Path where GNUstep and Etoile will be installed"
      echo "                            (default:  /)"
      echo "  --version               - Version of the Etoile environment to check out and "
      echo "                            and build, either 'stable' or 'trunk'. The related "
      echo "                            repository code will be checked out in "
      echo "                            $build-dir/Etoile"
      echo "                            (default: stable)"
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

# Create a build directory if none exists

if [ ! -d $BUILD_DIR ]; then
	mkdir $BUILD_DIR
else
	echo "Found existing build directory"
fi
cd $BUILD_DIR

# Install Etoile and GNUstep dependencies for Ubuntu 9.04 (copied from INSTALL.Ubuntu)
# Universe repository needs to be enabled in /etc/apt/sources.list for libonig-dev to show up

sudo aptitude install gobjc-4.3 libxml2-dev libxslt1-dev libffi-dev libssl-dev libjpeg62-dev libtiff4-dev libpng12-dev libgif-dev libfreetype6-dev libx11-dev libcairo2-dev libxft-dev libxmu-dev dbus libdbus-1-dev hal libstartup-notification0-dev libxcursor-dev libxss-dev xscreensaver g++ libpoppler-dev libonig-dev  lemon libgmp3-dev postgresql libpq-dev libavcodec-dev libavformat-dev libtagc0-dev libmp4v2-dev

# Install Subversion to be able to check out Etoile

sudo aptitude install subversion

# Check out and build the latest GNUstep release

export GSMAKE=gnustep-make-2.2.0
export GSBASE=gnustep-base-1.19.1
export GSGUI=gnustep-gui-0.17.0
export GSBACK=gnustep-back-0.17.0
export GSGORM=gorm-1.2.10

wget -nc ftp://ftp.gnustep.org/pub/gnustep/core/$GSMAKE.tar.gz
tar -xzf $GSMAKE.tar.gz
wget -nc ftp://ftp.gnustep.org/pub/gnustep/core/$GSBASE.tar.gz
tar -xzf $GSBASE.tar.gz
wget -nc ftp://ftp.gnustep.org/pub/gnustep/core/$GSGUI.tar.gz
tar -xzf $GSGUI.tar.gz
wget -nc ftp://ftp.gnustep.org/pub/gnustep/core/$GSBACK.tar.gz
tar -xzf $GSBACK.tar.gz

# Build & Install GNUstep

cd $GSMAKE
./configure --prefix=$PREFIX_DIR && make && sudo -E make install
cd ..

# Source the GNUstep shell script, and add it to the user's bashrc
. ${PREFIX_DIR%/}/System/Library/Makefiles/GNUstep.sh
echo ". ${PREFIX_DIR%/}/System/Library/Makefiles/GNUstep.sh" >> ~/.bashrc

cd $GSBASE
./configure && make && sudo -E make install
cd ..
cd $GSGUI
./configure && make && sudo -E make install
cd ..
cd $GSBACK
./configure --enable-graphics=cairo && make && sudo -E make install
cd ..

# Download latest Gorm release over FTP, uncompress and build it

wget -nc ftp://ftp.gnustep.org/pub/gnustep/dev-apps/$GSGORM.tar.gz
tar -xzf $GSGORM.tar.gz

cd $GSGORM
make && sudo -E make install
cd ..

# Download and install LLVM 2.5

# Also apply a patch for bug http://llvm.org/bugs/show_bug.cgi?id=3801
# , otherwise all Smalltalk tests crash on Linux/x86
# TODO: remove this once the bug is fixed.

wget -nc http://llvm.org/releases/2.5/llvm-2.5.tar.gz
tar -xzf llvm-2.5.tar.gz
cd llvm-2.5
wget -O llvm.patch http://llvm.org/bugs/attachment.cgi?id=2744
sudo aptitude install patch
patch -p0 < llvm.patch
./configure && make && sudo make install
cd ..

# Check out and build the requested Etoile version

if [ $ETOILE_VERSION = stable ]; then
	ETOILE_REP_PATH=stable
elif [ $ETOILE_VERSION = trunk ]; then
	ETOILE_REP_PATH=trunk/Etoile
fi

svn co http://svn.gna.org/svn/etoile/$ETOILE_REP_PATH Etoile

cd Etoile
make && sudo -E make install
./setup.sh

echo
echo "--> Finished Etoile installation :-)"
echo
echo "You now need to log out and choose Etoile session in GDM, then log in "
echo "to start Etoile."
echo

# TODO: Make possible to skip setup.sh and run it later manually
#echo
#echo "Installation of Etoile is almost finished, you now need to run setup.sh "
#echo "script by yourself to have a usable environment."
#echo
#echo " -- The script path is $BUILD_DIR/Etoile/setup.sh -- "
#echo

