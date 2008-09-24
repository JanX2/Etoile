ETOILE_CORE_MODULE = YES

include $(GNUSTEP_MAKEFILES)/common.make

# Ugly hack to shut down the compiler warning: 'method possibly missing a 
# [super dealloc] call' for -[NSObject(CycleDetection) dealloc]
# No flag currently exists to turn off this check so we ignore all warnings to 
# get rid of -Werror defined in etoile.make
ADDITIONAL_OBJCFLAGS += -w

ADDITIONAL_OBJCFLAGS += -std=c99

FRAMEWORK_NAME = GCKit
VERSION = 0.1

GCKit_LIBRARIES_DEPEND_UPON = $(FND_LIBS) $(OBJC_LIBS) $(SYSTEM_LIBS)

GCKit_OBJC_FILES = \
	cycle.m

GCKit_HEADER_FILES = 

include $(GNUSTEP_MAKEFILES)/framework.make
-include ../../etoile.make
