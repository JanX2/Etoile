#!/bin/sh

PKG_CONFIG=`which pkg-config 2>/dev/null`
if [ -z "${PKG_CONFIG}" ]; then
   echo "pkg-config not found!"
   exit 1
fi

# poppler
${PKG_CONFIG} --exists poppler
if [ $? -ne 0 ]; then
   echo "poppler library required but not found!"
   exit 1
fi
POPPLER_CFLAGS=`${PKG_CONFIG} --cflags poppler`
POPPLER_LIBS="${POPPLER_LDFLAGS} `${PKG_CONFIG} --libs poppler`"

# fontconfig
${PKG_CONFIG} --exists fontconfig
if [ $? -ne 0 ]; then
    echo "fontconfig library required but not found!"
    exit 1
fi
POPPLER_CFLAGS="${POPPLER_CFLAGS} `${PKG_CONFIG} --cflags fontconfig`"
POPPLER_LIBS="${POPPLER_LDFLAGS} `${PKG_CONFIG} --libs fontconfig`"

# poppler splash device
${PKG_CONFIG} --exists poppler-splash
if [ $? -ne 0 ]; then
    echo "poppler-splash required not found!"
    exit 1
fi
POPPLER_CFLAGS="${POPPLER_CFLAGS} `${PKG_CONFIG} --cflags poppler-splash`"
POPPLER_LIBS="${POPPLER_LDFLAGS} `${PKG_CONFIG} --libs poppler-splash`"

# poppler cairo device
${PKG_CONFIG} --exists poppler-cairo
if [ $? -ne 0 ]; then
   echo "poppler-cairo not found, building without cairo rendering"
   HAVE_CAIRO="NO"
else
#   Disable Cairo support for now to avoid most of problem
#   HAVE_CAIRO="YES"
#   POPPLER_CFLAGS="${POPPLER_CFLAGS} `${PKG_CONFIG} --cflags poppler-cairo`"
#   POPPLER_LIBS="${POPPLER_LDFLAGS} `${PKG_CONFIG} --libs poppler-cairo`"
   HAVE_CAIRO="NO"
fi

# check poppler version
${PKG_CONFIG} --atleast-version=0.4 poppler
if [ $? -eq 0 ]; then
  POPPLER_VERSION="POPPLER_0_4"
else
  echo "PopplerKit does not support this version of poppler"
  exit 1
fi

${PKG_CONFIG} --atleast-version=0.5 poppler
if [ $? -eq 0 ]; then
  POPPLER_VERSION="POPPLER_0_5"
fi

# include freetype, just to be sure
${PKG_CONFIG} --exists freetype2
if [ $? -eq 0 ]; then
   FT_CFLAGS=`${PKG_CONFIG} --cflags freetype2`
   FT_LIBS=`${PKG_CONFIG} --libs freetype2`
else
   FT_CONFIG=`which freetype-config 2>/dev/null`
   if [ -z "${FT_CONFIG}" ]; then
      echo "freetype2 library required but not found!"
      exit 1
   fi
   FT_CFLAGS=`${FT_CONFIG} --cflags`
   FT_LIBS=`${FT_CONFIG} --libs`
fi

# write config.make
echo "# config.make, generated at `date`" >config.make
echo "POPPLER_CFLAGS=${POPPLER_CFLAGS}" >>config.make
echo "POPPLER_LIBS=${POPPLER_LIBS}" >>config.make
echo "${POPPLER_VERSION}=YES" >> config.make
echo "FT_CFLAGS=${FT_CFLAGS}" >> config.make
echo "FT_LIBS=${FT_LIBS}" >> config.make
echo "ADDITIONAL_CFLAGS=\$(POPPLER_CFLAGS) \$(FT_CFLAGS)" >> config.make
echo "ADDITIONAL_LDFLAGS=\$(POPPLER_LIBS) \$(POPPLER_LIBS)" >> config.make
echo "HAVE_CAIRO=${HAVE_CAIRO}" >>config.make

exit 0
