include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = MultimediaKit_Source

MultimediaKit_Source_OBJC_FILES = \
	MixerView.m \
	MixerChannelView.m \
	MixerChannel.m \
	Mixer.m \
	MPlayer.m \
	MPlayerInterface.m

MultimediaKit_Source_INCLUDE_DIRS += -I..
ADDITIONAL_CFLAGS +=
ADDITIONAL_INCLUDE_DIRS += -I/usr/include -I/usr/X11R6/include
ADDITIONAL_LIB_DIRS += -L/usr/lib -L/usr/X11R6/lib -lX11

-include ../../GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/subproject.make
-include GNUmakefile.postamble

