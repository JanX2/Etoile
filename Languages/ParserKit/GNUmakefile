include $(GNUSTEP_MAKEFILES)/common.make

#
# Application
#
VERSION = 0.1
TOOL_NAME = ParserKit

${TOOL_NAME}_LANGUAGES = English

${TOOL_NAME}_OBJC_FILES = \
	NSInvocation+pkextention.m\
	NSString+append.m\
	NSScanner+returnValue.m\
	PKMain.m

${TOOL_NAME}_OBJCFLAGS = -std=c99 -g -Wno-unused-value
${TOOL_NAME}_LDFLAGS += -g -lgmp -lEtoileFoundation -lgnustep-gui\
	-L/usr/local/lib -march=native

${TOOL_NAME}_SMALLTALK_FILES += ParserKit.st

ADDITIONAL_OBJCFLAGS +=  -march=native

${TOOL_NAME}_CFLAGS += -Wno-implicit -g 


include ../../smalltalk.make
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/tool.make

