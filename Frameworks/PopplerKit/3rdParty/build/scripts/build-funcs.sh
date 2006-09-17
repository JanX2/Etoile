# common functions for building 3rdParty stuff

# call with $@ from including script
build_init() {
   PREFIX=${1}
   if [ -z "${PREFIX}" ]; then
      echo "first parameter must be install prefix"
      return 1
   fi
   
   ARTIFACT_DIR=${2}
   if [ -z "${ARTIFACT_DIR}" ]; then
      echo "second parameter must be the artifact's build directory"
      return 1
   fi
   if [ ! -d "${ARTIFACT_DIR}" ]; then
      echo "${ARTIFACT_DIR} not found"
      return 1
   fi

   return 0
}

# emit an error message and exit with retcode 1 if the first parameter is non-zero
build_exit_if_failed() {
   if [ $1 -ne 0 ]; then
      echo "BUILD FAILED"
      exit 1
   fi 
}