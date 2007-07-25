include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = NewsParser

NewsParser_SUBPROJECTS = CurlGetDate

NewsParser_OBJC_FILES = \
	StringExtensions.m \
	ArrayExtensions.m \
	XMLTag.m \
	XMLFunctions.m \
	RichXMLParser.m \

ADDITIONAL_OBJCFLAGS = -ICurlGetDate/ #`curl-config --cflags`
#ADDITIONAL_LDFLAGS = `curl-config --libs`

include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/subproject.make

