# An example GNUmakefile
#

# Include the common variables defined by the Makefile Package
include $(GNUSTEP_MAKEFILES)/common.make

# Build a simple Objective-C program
TOOL_NAME = ETSerialiserTest
DOCUMENT_NAME = EtoileSerialise

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

EtoileSerialise_AGSDOC_FILES = ${ETSerialiserTest_OBJC_FILES} \
							   COProxy.h\
							   ETDeserialiserBinaryFile.h\
						 	   ETSerialiserBackendBinaryFile.h\
							   ETSerialiserNullBackend.h\
							   ETDeserialiser.h\
			   				   ETSerialiser.h\
			 				   ETSerialiserBackendExample.h

OBJCFLAGS += -std=c99 -Wall -W -Wunreachable-code -Winline -Werror -Wno-unused -Wno-format -g
LDFLAGS += -g

-include GNUmakefile.preamble

# Include in the rules for making command line tools
include $(GNUSTEP_MAKEFILES)/tool.make
# Uncomment this when gsdoc is fixed and doesn't generate loads or errors because it can't parse id<foo> properly
#include $(GNUSTEP_MAKEFILES)/documentation.make

-include GNUmakefile.postamble


