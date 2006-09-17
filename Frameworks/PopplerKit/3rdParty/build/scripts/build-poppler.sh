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
   --disable-shared \
   --disable-poppler-glib \
   --disable-poppler-qt \
   --without-x

build_exit_if_failed $?
      
# 'disable' CairoOutputDevX by overwriting the sources
echo "// disabled" > poppler/CairoOutputDevX.h
echo "// disabled" > poppler/CairoOutputDevX.cc

make \
&& \
make install

build_exit_if_failed $?

exit 0
