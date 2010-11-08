include $(GNUSTEP_MAKEFILES)/common.make

VERSION = 0.1
FRAMEWORK_NAME = ScriptKit

ScriptKit_OBJC_FILES = \
				  ScriptCenter.m\
				  Tell.m

ScriptKit_HEADER_FILES = \
				  ScriptCenter.h\
				  Tell.h

ADDITIONAL_OBJCFLAGS = -std=c99 -g -Werror 

ADDITIONAL_LDFLAGS += -lgnustep-gui

include $(GNUSTEP_MAKEFILES)/framework.make
-include ../../etoile.make
-include ../../documentation.make
