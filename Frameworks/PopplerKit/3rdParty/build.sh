#!/bin/sh
#

# setup everything
setup() {
   setup_env
   prepare_env
   find_getprg
   load_sources
   load_files
}

# setup the environment
setup_env () {
   # load global environment
   ENV_SCRIPT=`pwd`/env
   if [ ! -f ${ENV_SCRIPT} ]; then
      echo "$ENV_SCRIPT not found! Execute from 3rdParty directory!"
      exit 1
   fi
   . ${ENV_SCRIPT}
   # load system dependent environment
   SYS_ENV_SCRIPT=${ENV_SCRIPT}.`uname -s`
   if [ -f ${SYS_ENV_SCRIPT} ]; then
      . ${SYS_ENV_SCRIPT}
   fi
}

# prepare the build environment
prepare_env() {
   # artifacts build dir
   if [ ! -d ${BUILD_ARTIFACTS} ]; then
      mkdir ${BUILD_ARTIFACTS}
   fi
}

# remove all intermediate build products for all artifacts
clean_build_all() {
   if [ -d ${BUILD_ARTIFACTS} ]; then
      echo "removing all build products ..."
      rm -rf ${BUILD_ARTIFACTS}
   fi
}

# remove all intermediate build products for a particular artifact
clean_build_artifact() {
   if [ -z "${1}" ]; then
      echo "no artifact specified"
      return
   fi
   ARTIFACT_DIR_VAR="\$${1}_DIR"
   ARTIFACT_DIR="${BUILD_ARTIFACTS}/`eval echo ${ARTIFACT_DIR_VAR=}`"
   if [ -d ${ARTIFACT_DIR} ]; then
      echo "removing build products for ${1} ..."
      rm -rf ${ARTIFACT_DIR}
   fi
}

# find a program to download artifact archives
find_getprg() {
   GET_PRG=`which fetch 2>/dev/null`
   if [ $? -eq 0 ]; then
     GET_CMD="${GET_PRG} -o ${DISTFILES}"
   else 
      GET_PRG=`which wget 2>/dev/null`
      if [ $? -eq 0 ]; then
         GET_CMD="${GET_PRG} -O ${DISTFILES}"
      else
         GET_PRG=`which curl 2>/dev/null`
         if [ $? -eq 0 ]; then
            GET_CMD="${GET_PRG} -o ${DISTFILES}"
         else
            GET_CMD=none
         fi
      fi
   fi
}

# load distribution sources
load_sources() {
   SOURCES=${DISTFILES}/sources
   if [ ! -f ${SOURCES} ]; then
      echo "${SOURCES} not found!"
      exit 1
   fi
   . ${SOURCES}
}

# load the file informations
load_files() {
   FILES=${THIRD_PARTY_ROOT}/files
   if [ ! -f ${FILES} ]; then
      echo "ERROR: ${FILES} not found!"
      exit 1
   fi
   . ${FILES}
}

# unpack an archive
unpack_archive() {
   ARCHIVE=${1}
   DEST=${2}
   
   if [ `expr match "${ARCHIVE}" ".*\.gz"` != 0 ]; then
      PRG="gzip"
   else
      if [ `expr match "${ARCHIVE}" ".*\.bz2"` != 0 ]; then
         PRG="bzip2"
      fi
   fi

   if [ -z "${PRG}" ]; then
      echo "don't know how to unpack ${ARCHIVE}"
      exit 1
   fi

   echo "extracting ${ARCHIVE} ..."
   (cd ${DEST} && gzip -dc ${ARCHIVE} | tar xf -)
}

# download the archive for an artifact
download_artifact_archive() {
   if [ "${GET_CMD}" = "none" ]; then
      echo "you must have either fetch, wget or curl installed and on your path!"
      exit 1
   fi
   SRC_VAR="\$${1}_SOURCE"
   SRC=`eval echo ${SRC_VAR}`
   echo "download from ${SRC}"
   ${GET_CMD}/${PKG} ${SRC}/${2}
}

# check if an artifact is required for a specific system
should_build_artifact() {
   TARGET_SYSTEM=`uname -s`
   SYSTEMS_VAR="\$${1}_SYSTEMS"
   SYSTEMS=`eval echo ${SYSTEMS_VAR}`
   SUPPORTED=0
   for SYSTEM in $SYSTEMS; do
      if [ "${TARGET_SYSTEM}" = "${SYSTEM}" -o "${SYSTEM}" = "All" ]; then
         SUPPORTED=1
         break
      fi
   done
   return $SUPPORTED
}

# check if an artifact has already been build
is_artifact_uptodate() {
   ARTIFACT_DIR_VAR="\$${1}_DIR"
   ARTIFACT_DIR="${BUILD_ARTIFACTS}/`eval echo ${ARTIFACT_DIR_VAR=}`"
   IS_BUILD=0
   if [ -f ${ARTIFACT_DIR}/BUILD_STAMP ]; then
      IS_BUILD=1
   fi
   return ${IS_BUILD}
}

# do everything that is necessary to build an artifact
build_artifact() {
   ARTIFACT=${1}
   echo "--- ${ARTIFACT}"
   should_build_artifact ${ARTIFACT}
   if [ $? -ne 1 ]; then
      echo "skipping ${ARTIFACT} on this platform"
      return
   fi

   is_artifact_uptodate ${ARTIFACT}
   if [ $? -eq 1 ]; then
      echo "${ARTIFACT} has already been build"
      return
   fi

   PKG_VAR="\$${ARTIFACT}_PACKAGE"
   PKG=`eval echo ${PKG_VAR}`

   if [ ! -f ${DISTFILES}/${PKG} ]; then
      echo "${PKG} does not exist in distfiles, try to get it ..."
      download_artifact_archive ${ARTIFACT} ${PKG}
   fi
   
   unpack_archive ${DISTFILES}/${PKG} ${BUILD_ARTIFACTS}

   echo "build ${ARTIFACT} ..."

   BUILD_SCRIPT="${BUILD_SCRIPTS}/build-${ARTIFACT}-`uname -s`.sh"
   if [ ! -f ${BUILD_SCRIPT} ]; then
       BUILD_SCRIPT="${BUILD_SCRIPTS}/build-${ARTIFACT}.sh"
       if [ ! -f ${BUILD_SCRIPT} ]; then
          echo "no build-script for ${ARTIFACT} found!"
          exit 1
       fi
   fi
   echo "using build-script `basename ${BUILD_SCRIPT}`"

   ARTIFACT_DIR_VAR="\$${ARTIFACT}_DIR"
   ARTIFACT_DIR="${BUILD_ARTIFACTS}/`eval echo ${ARTIFACT_DIR_VAR=}`"

   (sh ${BUILD_SCRIPT} ${INSTALL_PREFIX} ${ARTIFACT_DIR})
   if [ $? -eq 0 ]; then
      echo "build finished at `date`" >${ARTIFACT_DIR}/BUILD_STAMP
   else
      echo "ERROR: build ${FILE} failed!"
      exit 1
   fi
}

echo "**************************************"
echo "Building required 3rd party components"
echo "**************************************"
echo "NOTE: you need to have either wget, fetch or curl on your PATH"
echo "If you don't want the build script to download the packages, "
echo "you can download them yourself and place the files in the distfiles"
echo "directory. See building instructions for a list of required files"
echo "and sources. "
echo

setup

case $1 in
   build)
      if [ -z "${2}" ]; then
         for FILE in ${FILES}; do
            build_artifact ${FILE}
         done
      else
         build_artifact ${2}
      fi
   ;;
   clean)
      if [ -z "${2}" ]; then
         clean_build_all
      else
         clean_build_artifact ${2}
      fi
   ;;
   *)
      echo "usage: build.sh build|clean [artifact]"
      exit 1
   ;;
esac

exit 0


