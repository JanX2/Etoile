include $(GNUSTEP_MAKEFILES)/common.make

VERSION = 0.1
FRAMEWORK_NAME = MediaKit

MediaKit_OBJC_FILES = \
				  MKObjectPipe.m\
				  MKMediaFile.m\
				  MKMusicPlayer.m\
				  MKSoundDevice.m\
				  oss.m

MediaKit_HEADER_FILES = \
				MKMediaFile.h\
				MKMusicPlayer.h\
				MKSoundDevice.h

ADDITIONAL_OBJCFLAGS = -std=c99
ADDITIONAL_OBJCFLAGS += `pkg-config libavcodec --cflags`
ADDITIONAL_OBJCFLAGS += `pkg-config libavformat --cflags`
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

# If you install OSS 4 in Ubuntu, the header files are located here:
ADDITIONAL_OBJCFLAGS += -I/usr/lib/oss/include

ADDITIONAL_LDFLAGS += -lgnustep-gui -lEtoileFoundation -lSystemConfig
ADDITIONAL_LDFLAGS += `pkg-config libavcodec --libs`
ADDITIONAL_LDFLAGS += `pkg-config libavformat --libs`

include $(GNUSTEP_MAKEFILES)/framework.make
-include ../../etoile.make
-include ../../documentation.make
