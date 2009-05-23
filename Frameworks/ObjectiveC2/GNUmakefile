include $(GNUSTEP_MAKEFILES)/common.make

#
# Application
#
VERSION = 0.1
FRAMEWORK_NAME = ObjectiveC2

#
# Resource files
#
ObjectiveC2_LANGUAGES = English

ObjectiveC2_OBJC_FILES = \
				NSBlocks.m\
				blocks_runtime.m\
				ObjectPlanes.m\
				properties.m\
				sync.m


ObjectiveC2_C_FILES = \
				runtime.c

ObjectiveC2_HEADER_FILES = \
					  blocks_runtime.h\
					  ObjectPlanes.h\
					  runtime.h

ADDITIONAL_CFLAGS = -std=c99 -fexceptions 
ADDITIONAL_OBJCFLAGS = -fobjc-exceptions -fexceptions -march=i686 

ObjectiveC2_OBJCFLAGS += -std=c99

include $(GNUSTEP_MAKEFILES)/framework.make
