# configure scripts & files path to the backends
# Carlos Garnacho 2004

dnl AM_PATH_SYSTEM_TOOLS_BACKENDS([MINIMUM-VERSION [,ACTION-IF-FOUND [,ACTION-IF-NOT-FOUND]]])
dnl Tests for the system tools backends and define STB_SCRIPTS_DIR

AC_DEFUN([AM_PATH_SYSTEM_TOOLS_BACKENDS],
[
  AC_PATH_PROG(PKG_CONFIG, pkg-config, no)
  stb="system-tools-backends"

  if test x$PKG_CONFIG != xno ; then
    if $PKG_CONFIG --atleast-pkgconfig-version 0.12 ; then
      min_version=ifelse([$1], ,1.0.0, $1)
      AC_MSG_CHECKING(for $stb >= $min_version)

      if $PKG_CONFIG --atleast-version $min_version $stb ; then
        STB_SCRIPTS_DIR=`$PKG_CONFIG --variable=backenddir $stb`
	   AC_MSG_RESULT(yes ($STB_SCRIPTS_DIR))
        ifelse([$2], , :, [$2])     
      else
	   AC_MSG_RESULT(no)
        ifelse([$3], , :, [$3])
      fi
    else
      echo "*** pkg-config too old; version 0.12 or better required."
    fi
  fi

  AC_SUBST(STB_SCRIPTS_DIR)
])
