include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORK_NAME = EtoileSerialise
DOCUMENT_NAME = EtoileSerialiseDoc

EtoileSerialise_SUBPROJECTS = Sources

# The Objective-C files to compile
ETSerialiserTest_OBJC_FILES = \
					StringMap.m\
					ETSerialiser.m\
				   	ETSerialiserBackendExample.m\
				   	ETSerialiserTest.m\
				   	ETSerialiserBackendBinaryFile.m\
					ETSerialiserNullBackend.m\
				   	ETDeserialiser.m\
				   	ETDeserialiserBinaryFile.m\
					COProxy.m\
					GSMutableString+ETSerialisable.m\
					NSDataStatic+ETSerialisable.m\
					NSInvocation+ETSerialisable.m

EtoileSerialise_HEADER_FILES_DIR = Headers


EtoileSerialise_HEADER_FILES = \
				   COProxy.h\
				   ETDeserialiserBinaryFile.h\
				   ETSerialiserBackendBinaryFile.h\
				   ETSerialiserNullBackend.h\
				   ETDeserialiser.h\
				   ETSerialiser.h\
				   ETSerialiserBackendExample.h

EtoileSerialiseDoc_AGSDOC_FILES = ${ETSerialiserTest_HEADER_FILES}

OBJCFLAGS += -std=c99 -Wall -W -Wunreachable-code -Winline -Werror -Wno-unused -Wno-format -g
LDFLAGS += -g

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
-include ../../etoile.make
include $(GNUSTEP_MAKEFILES)/framework.make
include $(GNUSTEP_MAKEFILES)/documentation.make

-include GNUmakefile.postamble


