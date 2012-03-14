include $(GNUSTEP_MAKEFILES)/common.make

#
# Application
#
VERSION = 0.1
TOOL_NAME = ParserKit

${TOOL_NAME}_LANGUAGES = English

${TOOL_NAME}_OBJC_FILES = \
	NSInvocation+pkextention.m\
	PKMain.m

${TOOL_NAME}_OBJCFLAGS = -std=c99 -g -Wno-unused-value
${TOOL_NAME}_LDFLAGS += -g -lgmp -lEtoileFoundation -lgnustep-gui\
	-L/usr/local/lib\
	-lSmalltalkSupport\
	smalltalk.optimised.o -march=i686

ADDITIONAL_OBJCFLAGS +=  -march=i686

${TOOL_NAME}_CFLAGS += -Wno-implicit -g 

SMALLTALK_FILES += ParserKit.st

all:: smalltalk.optimised.o

clean::
	rm -f smalltalk.optimised.* *.bc

include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/tool.make

smalltalk.optimised.o: ${SMALLTALK_FILES}
	@sh compile.sh ${SMALLTALK_FILES}
