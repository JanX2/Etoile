#!/bin/sh

# --build

if [ -d ./build ]; then
	mkdir build
else
	echo "Found existing build directory"
fi
cd build

# Install Etoile and GNUstep dependencies

sudo apt-get -y install gobjc-4.1 openssl libssl-dev libxml2-dev libxslt1-dev libffi4-dev libjpeg62-dev libtiff4-dev libpng12-dev libungif4-dev libfreetype6-dev libx11-dev libart-2.0-dev libxft-dev libxmu-dev libxss-dev xscreensaver libdbus-1-dev libstartup-notification0-dev g++ libpoppler-dev

# Install Subversion to be able to check both GNUstep and Etoile stable versions

sudo apt-get -y install subversion

# Check out and build GNUstep stable version

svn co http://svn.gna.org/svn/gnustep/tools/make/branches/stable gnustep-make
svn co http://svn.gna.org/svn/gnustep/libs/base/branches/stable gnustep-base
svn co http://svn.gna.org/svn/gnustep/libs/gui/branches/stable gnustep-gui
svn co http://svn.gna.org/svn/gnustep/libs/back/branches/stable gnustep-back

cd gnustep-make
./configure --prefix=/ && make && sudo make install
cd ..
. /System/Library/Makefiles/GNUstep.sh
cd gnustep-base
./configure && make && sudo make install
cd ..
cd gnustep-gui
./configure && make && sudo make install
cd ..
cd gnustep-back
./configure && make && sudo make install
cd ..

# Download latest StepTalk release over FTP, uncompress and build it

wget ftp://ftp.gnustep.org/pub/gnustep/libs/StepTalk-0.10.0.tar.gz
tar -xzf StepTalk-0.10.0.tar.gz
cd StepTalk
make && sudo make install
cd ..

# Download latest Gorm release over FTP, uncompress and build it

wget ftp://ftp.gnustep.org/pub/gnustep/dev-apps/gorm-1.2.1.tar.gz
tar -xzf gorm-1.2.1.tar.gz

cd gorm-1.2.1
make && sudo make install
cd ..

# Check out and build Etoile stable version

svn co http://svn.gna.org/svn/etoile/trunk/Dependencies Dependencies
svn co http://svn.gna.org/svn/etoile/stable/Etoile Etoile

cd Dependencies/oniguruma5
./configure && make && sudo make install # Build and install Oniguruma first
cd ../..
cd Etoile
make && sudo make install

# Register /usr/local/lib so libonig can be found by OgreKit
if [ -z `sed -n -e '/\/usr\/local\/lib/p' /etc/ld.so.conf` ]; then
	sudo sh -c 'echo "/usr/local/lib" >> /etc/ld.so.conf'
fi
sudo ldconfig

# Workaround install bug (probably related to gnustep-make)
# FIXME: Remove this hack.

sudo ln -s /Library/StepTalk /Local/Library/StepTalk
#ln -s /Library/Grr /Local/Library/Grr

echo
echo "Installation of Etoile is almost finished, you now need to run setup.sh "
echo "script by yourself to have a usable environment."
echo

