#!/bin/sh

if [ -z "${BUILD_SCRIPTS}" ]; then
   echo "BUILD_SCRIPTS is not set!"
   exit 1
fi

. ${BUILD_SCRIPTS}/build-funcs.sh

build_init $@
if [ $? -ne 0 ]; then
   echo "build_init failed"
   exit 1
fi

cd ${ARTIFACT_DIR}
./configure \
   --prefix=${PREFIX} \
&& \
make \
&&
make install

if [ $? -ne 0 ]; then
   echo "BUILD FAILED"
   exit 1
fi

exit 0