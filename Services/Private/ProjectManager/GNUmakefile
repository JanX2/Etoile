ETOILE_CORE_MODULE = YES

include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECTS = XCBKit
DEPENDENCIES = XCBKit

#
# Application
#
VERSION = 0.1
TOOL_NAME = ProjectManager

#
# Resource files
#
$(TOOL_NAME)_LANGUAGES = English

$(TOOL_NAME)_CPPFLAGS += -I.
$(TOOL_NAME)_LDFLAGS += -L./XCBKit/XCBKit.framework/

$(TOOL_NAME)_OBJC_FILES = \
	 PMNotifications.m\
	 PMConnectionDelegate.m \
	 PMScreen.m \
	 PMCompositeWindow.m \
	 PMManagedWindow.m \
	 PMNormalWindowDecorator.m \
	 main.m

$(TOOL_NAME)_TOOL_LIBS = -lXCBKit

$(TOOL_NAME)_HEADER_FILES =\
	PMManagedWindow.h \
	PMManagedWindowDecorator.h\
	PMCompositeWindow.h\
	PMScreen.h\
	PMNotifications.h\
	PMConnectionDelegate.h\
	PMNormalWindowDecorator.h

ADDITIONAL_OBJCFLAGS = -std=c99 -g -Wno-unused  -Werror -Wall

include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/tool.make
-include ../../../etoile.make
