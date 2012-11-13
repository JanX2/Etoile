#!/bin/sh

#
# This script is designed to be sourced in build.sh
#

# llvm-configure-basic.sh uses CONFIGURE variable that depends on LOG_RULE_TEMPLATE (see testbuild.profile)
export LOG_NAME=llvm-build

export LLVM_SOURCE_DIR=$BUILD_DIR/llvm-$LLVM_VERSION
if [ -n "$LLVM_INSTALL_DIR" ]; then
	LLVM_MAKE_INSTALL=$MAKE_INSTALL
	LLVM_PREFIX_DIR="--prefix-dir=$LLVM_INSTALL_DIR"
else
	LLVM_MAKE_INSTALL=
	# If we pass --prefix-dir=$LLVM_SOURCE_DIR/$LLVM_BUILD_OUTPUT, then 
	# Makes.rules in LLVM breaks because it sees a conflict between the 
	# built products location and the install destination. So we must be 
	# sure the LLVM configure uses the default prefix (/usr/local) if we
	# plan no installation.
	LLVM_PREFIX_DIR=
	# If there is no install dir, LLVM_INSTALL_DIR is set to the build output
	# directories... bin and lib inside LLVM_SOURCE_DIR
	LLVM_INSTALL_DIR=$LLVM_SOURCE_DIR/$LLVM_BUILD_OUTPUT
fi

# LLVM git mirror
LLVM_URL_GIT=http://llvm.org/git/llvm.git
# Clang git mirror
CLANG_URL_GIT=http://llvm.org/git/clang.git

if [ "$LLVM_VERSION" = "trunk" ]; then

	if [ "$LLVM_ACCESS" = "svn" ]; then

		echo "Fetching LLVM and Clang $LLVM_VERSION using SVN"
		${LLVM_SVN_ACCESS}llvm.org/svn/llvm-project/llvm/${LLVM_VERSION} $LLVM_SOURCE_DIR
		${LLVM_SVN_ACCESS}llvm.org/svn/llvm-project/cfe/${LLVM_VERSION} $LLVM_SOURCE_DIR/tools/clang 
		
	elif [ "$LLVM_ACCESS" = "git" ]; then

		if [ ! -d $LLVM_SOURCE_DIR ]; then
			echo "Fetching LLVM trunk using a GIT mirror at $LLVM_URL_GIT"
			git clone $LLVM_URL_GIT $LLVM_SOURCE_DIR
		else
			echo "Updating LLVM trunk using a GIT mirror at $LLVM_URL_GIT"
			git pull $LLVM_SOURCE_DIR
		fi
	fi

elif [ -n "$LLVM_VERSION" -a ! -d $LLVM_SOURCE_DIR ]; then

	echo "Fetching LLVM $LLVM_VERSION from LLVM release server"
	wget -nc http://llvm.org/releases/${LLVM_VERSION}/llvm-${LLVM_VERSION}.src.tar.gz
	tar -xzf llvm-${LLVM_VERSION}.src.tar.gz 
	mv llvm-${LLVM_VERSION}.src llvm-${LLVM_VERSION}
	echo "Fetching Clang $LLVM_VERSION from LLVM release server"
	wget -nc  http://llvm.org/releases/${LLVM_VERSION}/clang-${LLVM_VERSION}.src.tar.gz
	tar -xzf clang-${LLVM_VERSION}.src.tar.gz
	mv clang-${LLVM_VERSION}.src llvm-${LLVM_VERSION}/tools/clang
fi

echo

if [ -n "$LLVM_VERSION" ]; then

	echo "Building and Installing LLVM and Clang"
	echo

	# If LLVM has been successfully configured once, the codebase is not recompiled 
	# from scratch on every build unless --force-llvm-configure option is passed to build.sh
	LLVM_CONFIG_SUCCESS_FILE="$LLVM_SOURCE_DIR/config.success"

	if [ -f $LLVM_CONFIG_SUCCESS_FILE  -a "$FORCE_LLVM_CONFIGURE" != "yes" ]; then
		LLVM_CONFIGURE_ONCE=
	else
		LLVM_CONFIGURE_ONCE="eval $SCRIPT_DIR/$LLVM_CONFIGURE && touch $LLVM_CONFIG_SUCCESS_FILE"
	fi

	cd $LLVM_SOURCE_DIR
	($DUMP_ENV) && ($LLVM_CONFIGURE_ONCE) && ($MAKE_BUILD) && ($LLVM_MAKE_INSTALL)
	export STATUS=$?
	cd ..
	
	if [ $STATUS -eq 0 ]; then 
		# Put LLVM in the path (it must come first to take over any prior LLVM install)
		export PATH=$LLVM_INSTALL_DIR/bin:$PATH
		export LD_LIBRARY_PATH=$LLVM_INSTALL_DIR/lib:$LD_LIBRARY_PATH
		export CC=clang
	fi
fi
