#!/bin/sh

if [ ! -n "`which apt-get`" ]; then
	echo "WARNING: Dependencies have to be installed manually or using another script (apt-get is missing)."
	echo "You can comment out DEPENDENCY_SCRIPT variable in the build profile to turn off this warning."
	exit
fi

# Install Etoile and GNUstep dependencies for Ubuntu 9.04 (copied from INSTALL.Ubuntu)
# Universe repository needs to be enabled in /etc/apt/sources.list for libonig-dev to show up

sudo apt-get -q=2 install gobjc libxml2-dev libxslt1-dev libffi-dev libssl-dev libgnutls-dev libicu-dev libjpeg62-dev libtiff4-dev libpng12-dev libgif-dev libfreetype6-dev libx11-dev libcairo2-dev libxft-dev libxmu-dev dbus libdbus-1-dev hal libstartup-notification0-dev libxcursor-dev libxss-dev xscreensaver g++ libpoppler-dev libonig-dev  lemon libgmp3-dev postgresql libpq-dev libavcodec-dev libavformat-dev libtagc0-dev libmp4v2-dev libgraphviz-dev

# Install Subversion to be able to check out Etoile and Git for LLVM

sudo apt-get -q=2 install subversion git
