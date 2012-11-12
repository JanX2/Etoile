#!/bin/sh

LOG_NAME=gnustep-make-build

# Download, build and install GNUstep Make

echo "Fetching GNUstep Make into $PWD"
if [ "$MAKE_VERSION" = "trunk" ]; then

	${SVN_ACCESS}svn.gna.org/svn/gnustep/tools/make/${MAKE_VERSION} gnustep-make-${MAKE_VERSION}

elif [ -n "$MAKE_VERSION" ]; then

	wget -nc ftp://ftp.gnustep.org/pub/gnustep/core/gnustep-make-${MAKE_VERSION}.tar.gz
	tar -xzf gnustep-make-${MAKE_VERSION}.tar.gz

fi

if [ -n "$MAKE_VERSION" ]; then

	echo "Building & Installing GNUstep Make"
	cd gnustep-make-${MAKE_VERSION}
	($DUMP_ENV) && ( $CONFIGURE --prefix=$PREFIX_DIR --with-layout=gnustep --enable-debug-by-default --enable-objc-nonfragile-abi ) && ($MAKE_BUILD) && ($MAKE_INSTALL)
 	STATUS=$?
	cd ..

	if [ $STATUS -ne 0 ]; then exit 1; fi

	# Source the GNUstep shell script, and add it to the user's bashrc
	echo "Sourcing GNUstep.sh"
	. ${PREFIX_DIR%/}/System/Library/Makefiles/GNUstep.sh

fi
echo

# Download, build and install libobjc2 (aka GNUstep runtime)

LOG_NAME=gnustep-libobjc2-build

echo "Fetching libobjc2 into $PWD"
if [ "$RUNTIME_VERSION" = "trunk" ]; then

	${SVN_ACCESS}svn.gna.org/svn/gnustep/libs/libobjc2/${RUNTIME_VERSION} libobjc2-${RUNTIME_VERSION}

elif [ -n "$RUNTIME_VERSION" ]; then

	wget -nc http://download.gna.org/gnustep/libobjc2-${RUNTIME_VERSION}.tar.gz
	tar -xzf libobjc2-${RUNTIME_VERSION}.tar.gz

fi


if [ -n "$RUNTIME_VERSION" ]; then

	echo "Building & Installing libobjc2"
	cd libobjc2-${RUNTIME_VERSION}
	($DUMP_ENV) && ($MAKE_CLEAN) && ( MAKEOPTS="debug=no" $MAKE_BUILD ) && ( $MAKE_INSTALL strip=yes )
	STATUS=$?
	cd ..

	if [ $STATUS -ne 0 ]; then exit 2; fi

	# Reinstall GNUstep Make to get it detect the libobjc2 just installed

	export LOG_NAME=gnustep-make-build-2

	echo "Building & Installing GNUstep Make (second pass)"
	cd gnustep-make-${MAKE_VERSION}
	( $CONFIGURE --prefix=$PREFIX_DIR --with-layout=gnustep --enable-debug-by-default --enable-objc-nonfragile-abi ) && ($MAKE_BUILD) && ($MAKE_INSTALL)
	STATUS=$?
	cd ..

	if [ $STATUS -ne 0 ]; then exit 3; fi

	. ${PREFIX_DIR%/}/System/Library/Makefiles/GNUstep.sh

fi
echo 

# Download, build and install GNUstep Base

LOG_NAME=gnustep-base-build

echo "Fetching GNUstep Base into $PWD"
if [ "$BASE_VERSION" = "trunk" ]; then

	${SVN_ACCESS}svn.gna.org/svn/gnustep/libs/base/${BASE_VERSION} gnustep-base-${BASE_VERSION}


elif [ -n "$BASE_VERSION" ]; then

	wget -nc ftp://ftp.gnustep.org/pub/gnustep/core/gnustep-base-${BASE_VERSION}.tar.gz
	tar -xzf gnustep-base-${BASE_VERSION}.tar.gz
fi

if [ -n "$BASE_VERSION" ]; then

	echo "Building & Installing GNUstep Base"
	cd gnustep-base-${BASE_VERSION}
	($DUMP_ENV) && ($MAKE_CLEAN) && ($CONFIGURE) && ($MAKE_BUILD) && ($MAKE_INSTALL)
	STATUS=$?
	cd ..

	if [ $STATUS -ne 0 ]; then exit 4; fi

fi
echo

# Download, build and install GNUstep Gui

LOG_NAME=gnustep-gui-build

echo "Fetching GNUstep GUI into $PWD"
if [ "$GUI_VERSION" = "trunk" ]; then

	${SVN_ACCESS}svn.gna.org/svn/gnustep/libs/gui/${GUI_VERSION} gnustep-gui-${GUI_VERSION}


elif [ -n "$GUI_VERSION" ]; then

	wget -nc ftp://ftp.gnustep.org/pub/gnustep/core/gnustep-gui-${GUI_VERSION}.tar.gz
	tar -xzf gnustep-gui-${GUI_VERSION}.tar.gz

fi

if [ -n "$GUI_VERSION" ]; then

	echo "Building & Installing GNUstep Gui"
	cd gnustep-gui-${GUI_VERSION}
	($MAKE_CLEAN) && ($CONFIGURE) && ($MAKE_BUILD) && ($MAKE_INSTALL)
	STATUS=$?
	cd ..

	if [ $STATUS -ne 0 ]; then exit 5; fi

fi
echo

# Download, build and install GNUstep Back

LOG_NAME=gnustep-back-build

echo "Fetching GNUstep Back into $PWD"
if [ "$BACK_VERSION" = "trunk" ]; then

	${SVN_ACCESS}svn.gna.org/svn/gnustep/libs/back/${BACK_VERSION} gnustep-back-${BACK_VERSION}

elif [ -n "$BACK_VERSION" ]; then

	wget -nc ftp://ftp.gnustep.org/pub/gnustep/core/gnustep-back-${BACK_VERSION}.tar.gz
	tar -xzf gnustep-back-${GUI_VERSION}.tar.gz

fi

if [ -n "$BACK_VERSION" ]; then

	echo "Building & Installing GNUstep Back"
	cd gnustep-back-${BACK_VERSION}
	($MAKE_CLEAN) && ( $CONFIGURE --disable-mixedabi ) && ($MAKE_BUILD) && ($MAKE_INSTALL)
	STATUS=$?
	cd ..

	if [ $STATUS -ne 0 ]; then exit 6; fi
fi
echo 

# Download, build and install Gorm

LOG_NAME=gnustep-gorm-build

echo "Fetching GNUstep Gorm into $PWD"
if [ "$GORM_VERSION" = "trunk" ]; then

	${SVN_ACCESS}svn.gna.org/svn/gnustep/apps/gorm/${GORM_VERSION} gorm-${GORM_VERSION}

elif [ -n "$GORM_VERSION" ]; then

	wget -nc ftp://ftp.gnustep.org/pub/gnustep/dev-apps/gorm-${GORM_VERSION}.tar.gz
	tar -xzf gorm-${GORM_VERSION}.tar.gz

fi

if [ -n "$GORM_VERSION" ]; then

	echo "Building & Installing Gorm"
	cd gorm-${GORM_VERSION}
	($MAKE_CLEAN) && ($MAKE_BUILD) && ($MAKE_INSTALL)
	STATUS=$?
	cd ..

	if [ $STATUS -ne 0 ]; then exit 7; fi

fi

