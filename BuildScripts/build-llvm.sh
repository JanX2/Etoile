#!/bin/sh

#
# This script is designed to be sourced in build.sh
#

LOG_NAME=llvm-build

export LLVM_SOURCE_DIR=$BUILD_DIR/llvm-$LLVM_VERSION
export LLVM_INSTALL_DIR=$PREFIX_DIR/llvm-install-$LLVM_VERSION

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
	wget -nc http://llvm.org/releases/${LLVM_VERSION}/llvm-${LLVM_VERSION}.tar.gz
	tar -xzf llvm-{LLVM_VERSION}.tar.gz
	echo "Fetching Clang $LLVM_VERSION from LLVM release server"
	wget -nc  http://llvm.org/releases/${LLVM_VERSION}/clang-${LLVM_VERSION}.tar.gz
	tar -xzf clang-{LLVM_VERSION}.tar.gz
fi

echo

if [ -n "$LLVM_VERSION" ]; then

	echo "Building and Installing LLVM and Clang"
	echo

	cd $LLVM_SOURCE_DIR
	. $SCRIPT_DIR/${LLVM_CONFIGURE} && $MAKE_BUILD && $MAKE_INSTALL
	export STATUS=$?
	cd ..

	if [ $STATUS -eq 0 ]; then 
		# Put LLVM in the path (it must come first to take over any prior LLVM install)
		export PATH=$LLVM_INSTALL_DIR/bin:$PATH
		export LD_LIBRARY_PATH=$LLVM_INSTALL_DIR/lib:$LD_LIBRARY_PATH
		export CC=clang
	fi
fi
