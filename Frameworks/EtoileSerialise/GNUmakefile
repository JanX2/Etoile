# An example GNUmakefile
#

# Include the common variables defined by the Makefile Package
include $(GNUSTEP_MAKEFILES)/common.make

# Build a simple Objective-C program
TOOL_NAME = ETSerialiserTest

# The Objective-C files to compile
ETSerialiserTest_OBJC_FILES = \
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

OBJCFLAGS += -std=c99 -Wall -W -Wunreachable-code -Winline -Werror -Wno-unused -Wno-format -g
LDFLAGS += -g

-include GNUmakefile.preamble

# Include in the rules for making command line tools
include $(GNUSTEP_MAKEFILES)/tool.make

-include GNUmakefile.postamble


