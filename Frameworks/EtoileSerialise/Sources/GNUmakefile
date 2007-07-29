include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = libEtoileSerialise

libEtoileSerialise_OBJC_FILES = \
					COProxy.m \
					ETDeserialiser.m \
					ETDeserialiserBinaryFile.m \
					ETSerialiser.m \
					ETSerialiserBackendBinaryFile.m \
					ETSerialiserBackendExample.m \
					ETSerialiserNullBackend.m \
					ETSerialiserTest.m \
					GSMutableString+ETSerialisable.m \
					NSDataStatic+ETSerialisable.m \
					NSInvocation+ETSerialisable.m \
					StringMap.m

libEtoileSerialise_OBJCFLAGS += -g -std=c99

-include ../GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/subproject.make

-include ../GNUmakefile.postamble
