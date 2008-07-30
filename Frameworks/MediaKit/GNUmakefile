include $(GNUSTEP_MAKEFILES)/common.make

VERSION = 0.1
FRAMEWORK_NAME = MediaKit

MediaKit_OBJC_FILES = \
				  MKMediaFile.m\
				  MKMusicPlayer.m\
				  MKSoundDevice.m\
				  oss.m

MediaKit_HEADER_FILES = \
				MKMediaFile.h\
				MKMusicPlayer.h\
				MKSoundDevice.h

ADDITIONAL_OBJCFLAGS = -std=c99 -g -Werror `pkg-config libavcodec --cflags`
ADDITIONAL_OBJCFLAGS += `pkg-config libavcodec --cflags`
ADDITIONAL_OBJCFLAGS += `pkg-config libavformat --cflags`

ADDITIONAL_LDFLAGS += -lgnustep-gui -lEtoileFoundation 
ADDITIONAL_LDFLAGS += `pkg-config libavcodec --libs`
ADDITIONAL_LDFLAGS += `pkg-config libavformat --libs`

include $(GNUSTEP_MAKEFILES)/framework.make
-include ../../etoile.make