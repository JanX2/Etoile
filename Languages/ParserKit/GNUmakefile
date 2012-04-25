include $(GNUSTEP_MAKEFILES)/common.make

#
# Application
#
VERSION = 0.1
FRAMEWORK_NAME = ParserKit


${FRAMEWORK_NAME}_OBJC_FILES = \
	NSInvocation+pkextention.m\
	NSString+append.m\
	NSScanner+returnValue.m	
#PKMain.m

${FRAMEWORK_NAME}_OBJCFLAGS = -std=c99 -g -Wno-unused-value
${FRAMEWORK_NAME}_LDFLAGS += -g -lgmp -lEtoileFoundation -lgnustep-gui\
	-L/usr/local/lib -march=native

${FRAMEWORK_NAME}_HEADER_FILES += PKParser.h\
	PKInputStream.h\
	PKMatches.h

${FRAMEWORK_NAME}_SMALLTALK_FILES += ParserKit.st

ADDITIONAL_OBJCFLAGS +=  -march=native

${TOOL_NAME}_CFLAGS += -Wno-implicit -g 


include ../../smalltalk.make
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/framework.make

