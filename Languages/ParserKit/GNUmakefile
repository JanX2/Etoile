include $(GNUSTEP_MAKEFILES)/common.make

#
# Application
#
VERSION = 0.1
FRAMEWORK_NAME = ParserKit
BUNDLE_NAME = ParserKitTest

${FRAMEWORK_NAME}_OBJC_FILES = \
	NSInvocation+pkextention.m\
	NSString+append.m\
	NSScanner+returnValue.m	
#PKMain.m

${FRAMEWORK_NAME}_OBJCFLAGS = -std=c99 -g -Wno-unused-value
${FRAMEWORK_NAME}_LDFLAGS += -g -lgmp -lEtoileFoundation \
	-L/usr/local/lib -march=native


${FRAMEWORK_NAME}_HEADER_FILES += PKParser.h\
	PKInputStream.h\
	PKMatches.h

${FRAMEWORK_NAME}_SMALLTALK_BUNDLES += ParserKit.bundle
ST_FILES = ParserKit.st\
	Utils.st\
	PKDelayActionArray.st\
	PKInputStream.st\
	PKEnvironmentStack.st

SMALLTALK_BUNDLE_ST_FILES=$(addprefix ./ParserKit.bundle/Resources/,$(ST_FILES))
ADDITIONAL_OBJCFLAGS +=  -march=native
${TOOL_NAME}_CFLAGS += -Wno-implicit -g 

${BUNDLE_NAME}_OJCFLAGS = -std=c99 -g -Wno-unused-value
${BUNDLE_NAME}_LDFLAGS += -g -lgmp -lEtoileFoundation -lLanguageKit -lParserKit \
	-L/usr/local/lib -L./ParserKit.framework/Versions/Current/ -march=native
${BUNDLE_NAME}_OBJC_FILES = \
	Tests/PKParserASTGeneratorTest.m\
	Tests/PKParseMatchTest.m\
	Tests/PKInputStreamTest.m\
	Tests/PKEnvironmentTest.m

${BUNDLE_NAME}_OBJC_LIBS += -lUnitKit

include ../../smalltalk.make
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/framework.make
include $(GNUSTEP_MAKEFILES)/bundle.make

