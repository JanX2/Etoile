include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME=UnitTests

ADDITIONAL_TOOL_LIBS+= \
-lPopplerKit \
-L../PopplerKit.framework/Versions/Current \
-lgnustep-base \
-lgnustep-gui \
-lObjcUnit \
-lMocKit

UnitTests_OBJCFLAGS=-g -Wall -Wno-import -I../.. -DGNUSTEP

UnitTests_OBJC_FILES=\
AllTests.m \
PopplerDocumentTest.m \
PopplerPageTest.m \
PopplerRendererTest.m \
PopplerTextSearchTest.m \
PopplerCachingRendererTest.m \
TestSettings.m

include $(GNUSTEP_MAKEFILES)/tool.make


