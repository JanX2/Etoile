include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_CPPFLAGS += -std=c99
ADDITIONAL_OBJCFLAGS += -I.  -Wall -W -Wunreachable-code -Winline -Wno-unused -Wno-format

# Taglib
# In Ubuntu, libtag_c doesn't have pkg-config data
ADDITIONAL_LDFLAGS += `pkg-config --libs taglib` -ltag_c
ADDITIONAL_OBJCFLAGS += `pkg-config --cflags taglib`
# mp4v2
ADDITIONAL_LDFLAGS += -lmp4v2
# CoreObject
ADDITIONAL_INCLUDE_DIRS += -I`pg_config --includedir`
ADDITIONAL_LIB_DIRS += -L`pg_config --libdir`

# Workaround new FFMpeg header include style until we update MediaKit headers 
# to use <libavcodec/avcodec.h> and <libavformat/avformat.h>. For now, we have 
# to wait otherwise we would break many recent systems released around 2008 or 
# before, and which include FFMpeg releases/snapshots older than March 2008.
# FreeBSD has compatibility headers to support both old and new include style, 
# most other systems don't. For example:
# - on Ubuntu 9.04, avcodec.h is located in /usr/include/libavcodec, 
# pkg-config returns '' because you are expected to use <libavcodec/avcodec.h>
# - on Ubuntu 7.10, avcodec.h is located in /usr/include/ffmpeg and pkg-config 
# returns '-I/usr/include/ffmpeg' because you are expected to use <avcodec.h>
# 
# See also: https://mail.gna.org/public/etoile-discuss/2008-11/msg00085.html 
# and http://lists.mplayerhq.hu/pipermail/ffmpeg-devel/2008-April/046144.html

                #echo `pkg-config --cflags-only-I libavcodec` | sed 's/[ ]*$$/\/ libavcodec/g';\

NEW_AVCODEC_INCLUDE_DIR = $(shell if [ `pkg-config --cflags-only-I libavcodec | sed 's/ //g'` ];  then\
                echo `pkg-config --cflags-only-I libavcodec | sed 's/[ ]*$$/\/libavcodec/g'`;\
         else\
                echo -I/usr/include/libavcodec;\
         fi)
NEW_AVFORMAT_INCLUDE_DIR = $(shell if [ `pkg-config --cflags-only-I libavformat | sed 's/ //g'` ];  then\
                echo `pkg-config --cflags-only-I libavformat | sed 's/[ ]*$$/\/libavformat/g'`;\
        else\
                echo -I/usr/include/libavformat;\
        fi)


ADDITIONAL_OBJCFLAGS += $(NEW_AVCODEC_INCLUDE_DIR) $(NEW_AVFORMAT_INCLUDE_DIR)

APP_NAME = Melodie

$(APP_NAME)_APPLICATION_ICON = $(APP_NAME).tiff
$(APP_NAME)_OBJC_FILES = $(wildcard *.m)
$(APP_NAME)_PRINCIPAL_CLASS = ETApplication
$(APP_NAME)_MAIN_MODEL_FILE = $(APP_NAME).gorm
$(APP_NAME)_RESOURCE_FILES = $(APP_NAME).gorm $(APP_NAME).tiff $(wildcard *.st) LKInfo.plist
$(APP_NAME)_GUI_LIBS = -lEtoileFoundation -lCoreObject -lIconKit -lMediaKit -lEtoileUI
$(APP_NAME)_GUI_LIBS += -lLanguageKit -lSmalltalkSupport -lScriptKit

include $(GNUSTEP_MAKEFILES)/application.make
-include ../../../etoile.make
