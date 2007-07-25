include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = CurlGetDate

CurlGetDate_OBJC_FILES = \
	CurlGetDate.m

ADDITIONAL_OBJCFLAGS = `curl-config --cflags`
ADDITIONAL_LDFLAGS = `curl-config --libs`

include $(GNUSTEP_MAKEFILES)/subproject.make

