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

BUNDLE_NAME = SQLite

BUNDLE_INSTALL_DIR=$(GNUSTEP_INSTALLATION_DIR)/Library/Bundles/SQLClient

# In some systems and situations the dynamic linker needs to haved the
# SQLClient, gnustep-base, and objc libraries explicityly linked into
# the bundle, but in others it requires them to not be linked.
# To handle that, we create two versions of each bundle, the seond version
# has _libs appended to the bundle name, and has the extra libraries linked.

SQLite_OBJC_FILES = SQLite.m
SQLite_LIB_DIRS = -L./obj -L/opt/local/lib
SQLite_BUNDLE_LIBS += -lsqlite3 -lSQLClient
SQLite_PRINCIPAL_CLASS = SQLClientSQLite
BUNDLE_NAME += SQLite_libs
SQLite_libs_OBJC_FILES = SQLite.m
SQLite_libs_LIB_DIRS = -L./obj -L/opt/local/lib
SQLite_libs_BUNDLE_LIBS += -lSQLClient -lgnustep-base -lobjc -lsqlite3
SQLite_libs_PRINCIPAL_CLASS = SQLClientSQLite_libs

endif

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/library.make
include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble
