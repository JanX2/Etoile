#!/bin/sh

# --build

if [ ! -d ./build ]; then
	mkdir build
else
	echo "Found existing build directory"
fi
cd build

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
./configure --prefix=/ && make && sudo -E make install
cd ..

# Source the GNUstep shell script, and add it to the user's bashrc
. /System/Library/Makefiles/GNUstep.sh
echo ". /System/Library/Makefiles/GNUstep.sh" >> ~/.bashrc

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

# Check out and build Etoile stable version

svn co http://svn.gna.org/svn/etoile/stable/Etoile Etoile

cd Etoile
make && sudo -E make install

echo
echo "Installation of Etoile is almost finished, you now need to run setup.sh "
echo "script by yourself to have a usable environment."
echo

