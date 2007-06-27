include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_INCLUDE_DIRS += -I/usr/include -I/usr/X11R6/include
ADDITIONAL_LIB_DIRS += -L/usr/lib -L/usr/X11R6/lib -lX11

FRAMEWORK_NAME = MultimediaKit

MultimediaKit_SUBPROJECTS = Source

MultimediaKit_HEADER_FILES_DIR = Headers

MultimediaKit_HEADER_FILES = \
        MixerView.h \
        MixerChannelView.h \
        MixerChannel.h \
        Mixer.h \
        MMPlayer.h \
        MPlayer.h \
        MPlayerInterface.h \
        MultimediaKit.h

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/aggregate.make
-include ../../etoile.make
include $(GNUSTEP_MAKEFILES)/framework.make

-include GNUmakefile.postamble
