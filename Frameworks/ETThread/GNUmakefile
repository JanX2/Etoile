include $(GNUSTEP_MAKEFILES)/common.make

CFLAGS += -g 

DOCUMENT_NAME = ETThread
TOOL_NAME = ETThread

ETThread_OBJC_FILES = ETThread.m ETThreadProxyReturn.m ETThreadTest.m ETThreadedObject.m NSObject+Threaded.m
ETThread_HEADER_FILES = ETThread.h ETThreadProxyReturn.h ETThreadedObject.h NSObject+Threaded.h
ETThread_AGSDOC_FILES = $(ETThread_HEADER_FILES)


include $(GNUSTEP_MAKEFILES)/documentation.make
include $(GNUSTEP_MAKEFILES)/tool.make
