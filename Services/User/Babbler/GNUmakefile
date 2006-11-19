
include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = Babbler

Babbler_OBJC_FILES = \
	main.m \
	Controller.m \
	StreamPanel.m \
	Player.m

Babbler_RESOURCE_FILES = \
	Resources/pause.tiff \
	Resources/play.tiff \
	Resources/seek_back.tiff \
	Resources/seek_fwd.tiff

ADDITIONAL_INCLUDE_DIRS += -I/usr/X11R6/include
ADDITIONAL_LIB_DIRS += -lXWindowServerKit -lMultimediaKit

include $(GNUSTEP_MAKEFILES)/application.make

