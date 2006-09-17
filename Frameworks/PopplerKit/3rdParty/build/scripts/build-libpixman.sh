#!/bin/sh

if [ -z "${BUILD_SCRIPTS}" ]; then
   echo "BUILD_SCRIPTS is not set!"
   exit 1
fi

sh ${BUILD_SCRIPTS}/build-default-lib.sh $@
exit $?
