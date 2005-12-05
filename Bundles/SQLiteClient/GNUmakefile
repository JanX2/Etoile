include $(GNUSTEP_MAKEFILES)/common.make

-include config.make

#
# On MacOS X, build SQClient and SQLite as a library.
# On GNUstep, only build SQLite as a bundle for SQClient.
#
ifeq ($(OBJC_RUNTIME_LIB),gnu)
APPLE=0
else
APPLE=1
endif

ifeq ($(APPLE),1)
PACKAGE_NAME = SQLClient
PACKAGE_VERSION = 1.1.0
CVS_MODULE_NAME = gnustep/dev-libs/SQLClient
CVS_TAG_NAME = SQLClient

LIBRARY_NAME=SQLClient

SQLClient_INTERFACE_VERSION=1.1

SQLClient_OBJC_FILES = SQLClient.m SQLite.m GSLock.m
SQLClient_LIBRARIES_DEPEND_UPON =
SQLClient_HEADER_FILES = SQLClient.h

ADDITIONAL_OBJC_LIBS += 
SQLClient_LIBRARIES_DEPEND_UPON = -lsqlite3
SQLClient_HEADER_FILES_INSTALL_DIR = SQLClient
else

$(error Please use official SQLClient with SQLite bundle from GNUstep/dev-libs)

endif

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/library.make

-include GNUmakefile.postamble
