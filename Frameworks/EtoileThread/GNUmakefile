include $(GNUSTEP_MAKEFILES)/common.make

CFLAGS += -g 

DOCUMENT_NAME = EtoileThread
FRAMEWORK_NAME = EtoileThread

EtoileThread_OBJC_FILES = EtoileThread.m EtoileThreadProxyReturn.m EtoileThreadedObject.m NSObject+Threaded.m NSObject+Futures.m
EtoileThread_HEADER_FILES = EtoileThread.h EtoileThreadProxyReturn.h EtoileThreadedObject.h NSObject+Threaded.h NSObject+Futures.h
EtoileThread_AGSDOC_FILES = $(EtoileThread_HEADER_FILES)


include $(GNUSTEP_MAKEFILES)/documentation.make
include $(GNUSTEP_MAKEFILES)/framework.make
