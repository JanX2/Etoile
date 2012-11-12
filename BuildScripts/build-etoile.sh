#!/bin/sh

LOG_NAME=etoile-build

# TODO: Support building tagged versions in Etoile SVN

if [ "$ETOILE_VERSION" = "stable" ]; then
	ETOILE_REP_PATH=stable
elif [ "$ETOILE_VERSION" = "trunk" ]; then
	ETOILE_REP_PATH=trunk/Etoile
fi

if [ -n "$ETOILE_VERSION" ]; then

	${SVN_ACCESS}svn.gna.org/svn/etoile/${ETOILE_REP_PATH} etoile-${ETOILE_VERSION}

	cd etoile-${ETOILE_VERSION}
	$MAKE_BUILD && $MAKE_INSTALL
	exit $?

else

	echo 
	echo "--> Finished... Warning: Etoile has not been built as requested!"
	echo
	exit # Don't report build failures if Etoile is not built

fi
