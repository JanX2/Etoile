#!/bin/sh

export LOG_NAME=gnustep-make-build

# Download, build and install GNUstep Make
echo "Fetching GNUstep Make into $PWD"
if [ "$MAKE_VERSION" = "trunk" ]; then

	${SVN_ACCESS}svn.gna.org/svn/gnustep/dev-libs/make/${MAKE_VERSION} gnustep-make-${MAKE_VERSION}

elif [ -n "$MAKE_VERSION" ]; then

	wget -nc ftp://ftp.gnustep.org/pub/gnustep/core/gnustep-make-${MAKE_VERSION}.tar.gz
	tar -xzf gnustep-make-${MAKE_VERSION}.tar.gz

fi

if [ -n "$MAKE_VERSION" ]; then

	cd gnustep-make-${MAKE_VERSION}
	( $CONFIGURE --prefix=$PREFIX_DIR --with-layout=gnustep --enable-debug-by-default ) && ($MAKE_BUILD) && ($MAKE_INSTALL)
	cd ..

	# Source the GNUstep shell script, and add it to the user's bashrc
	. ${PREFIX_DIR%/}/System/Library/Makefiles/GNUstep.sh
	echo ". ${PREFIX_DIR%/}/System/Library/Makefiles/GNUstep.sh" >> ~/.bashrc
fi
echo $PWD

# Download, build and install libobjc2 (aka GNUstep runtime)

export LOG_NAME=gnustep-libobjc2-build

if [ "$RUNTIME_VERSION" = "trunk" ]; then

	${SVN_ACCESS}svn.gna.org/svn/gnustep/dev-libs/libobjc2/${RUNTIME_VERSION} libobjc2-${RUNTIME_VERSION}

elif [ -n "$RUNTIME_VERSION" ]; then

	wget -nc http://download.gna.org/gnustep/libobjc2-${RUNTIME_VERSION}.tar.gz
	tar -xzf libobjc2-${RUNTIME_VERSION}.tar.gz

fi

if [ -n "$RUNTIME_VERSION" ]; then

	cd libobjc2-${RUNTIME_VERSION}
	($MAKE_CLEAN) && ( MAKEOPTS="debug=no" $MAKE_BUILD ) && ( $MAKE_INSTALL strip=yes )
	cd ..

	# Reinstall GNUstep Make to get it detect the libobjc2 just installed

	export LOG_NAME=gnustep-make-build-2

	cd gnustep-make-${MAKE_VERSION}
	( $CONFIGURE --prefix=$PREFIX_DIR --with-layout=gnustep --enable-debug-by-default ) && ($MAKE_BUILD) && ($MAKE_INSTALL)
	cd ..

	. ${PREFIX_DIR%/}/System/Library/Makefiles/GNUstep.sh
	echo ". ${PREFIX_DIR%/}/System/Library/Makefiles/GNUstep.sh" >> ~/.bashrc

fi

# Download, build and install GNUstep Base

export LOG_NAME=gnustep-base-build

if [ "$BASE_VERSION" = "trunk" ]; then

	${SVN_ACCESS}svn.gna.org/svn/gnustep/dev-libs/base/${BASE_VERSION} gnustep-base-${BASE_VERSION}


elif [ -n "$BASE_VERSION" ]; then

	wget -nc ftp://ftp.gnustep.org/pub/gnustep/core/gnustep-base-${BASE_VERSION}.tar.gz
	tar -xzf gnustep-base-${BASE_VERSION}.tar.gz
fi
echo " ---- $PWD"

if [ -n "$BASE_VERSION" ]; then

	cd gnustep-base-${BASE_VERSION}
	($MAKE_CLEAN) && ($CONFIGURE) && ($MAKE_BUILD) && ($MAKE_INSTALL)
	cd ..

fi
echo " ++++ $PWD"
# Download, build and install GNUstep Gui

export LOG_NAME=gnustep-gui-build

if [ "$GUI_VERSION" = "trunk" ]; then

	${SVN_ACCESS}svn.gna.org/svn/gnustep/dev-libs/gui/${GUI_VERSION} gnustep-gui-${GUI_VERSION}


elif [ -n "$GUI_VERSION" ]; then

	wget -nc ftp://ftp.gnustep.org/pub/gnustep/core/gnustep-gui-${GUI_VERSION}.tar.gz
	tar -xzf gnustep-gui-${GUI_VERSION}.tar.gz

fi

if [ -n "$GUI_VERSION" ]; then

	cd gnustep-gui-${GUI_VERSION}
	($MAKE_CLEAN) && ($CONFIGURE) && ($MAKE_BUILD) && ($MAKE_INSTALL)
	cd ..

fi

# Download, build and install GNUstep Back

export LOG_NAME=gnustep-back-build

if [ "$BACK_VERSION" = "trunk" ]; then

	${SVN_ACCESS}svn.gna.org/svn/gnustep/dev-libs/back/${BACK_VERSION} gnustep-back-${BACK_VERSION}

elif [ -n "$BACK_VERSION" ]; then

	wget -nc ftp://ftp.gnustep.org/pub/gnustep/core/gnustep-back-${BACK_VERSION}.tar.gz
	tar -xzf gnustep-back-${GUI_VERSION}.tar.gz

fi

if [ -n "$BACK_VERSION" ]; then

	cd gnustep-back-${BACK_VERSION}
	($MAKE_CLEAN) && ($CONFIGURE) && ($MAKE_BUILD) && ($MAKE_INSTALL)
	cd ..

fi

# Download, build and install Gorm

export LOG_NAME=gnustep-gorm-build

if [ "$GORM_VERSION" = "trunk" ]; then

	echo "WARNING: Installing Gorm from svn trunk is not supported yet"

elif [ -n "$GORM_VERSION" ]; then

	wget -nc ftp://ftp.gnustep.org/pub/gnustep/dev-apps/gorm-${GORM_VERSION}.tar.gz
	tar -xzf gorm-${GORM_VERSION}.tar.gz

	cd gorm-${GORM_VERSION}
	($MAKE_CLEAN) && ($MAKE_BUILD) && ($MAKE_INSTALL)
	cd ..

fi
