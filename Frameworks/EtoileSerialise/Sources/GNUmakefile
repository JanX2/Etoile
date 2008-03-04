include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = libEtoileSerialise

libEtoileSerialise_OBJC_FILES = \
					COProxy.m \
					COProxy_NSAttributedString.m \
					ETDeserialiser.m \
					ETDeserialiserBinaryFile.m \
					ETSerialiser.m \
					ETSerialiserBackendBinaryFile.m \
					ETSerialiserBackendExample.m \
					ETSerialiserNullBackend.m \
					GSArray+ETSerialisable.m \
					GSDictionary+ETSerialisable.m \
					GSSet+ETSerialisable.m \
					GSMutableString+ETSerialisable.m \
					NSDataStatic+ETSerialisable.m \
					NSInvocation+ETSerialisable.m \
					StringMap.m

ifeq ($(test), yes)
libEtoileSerialise_OBJC_FILES +=\
					ETSerialiserTest.m 
endif

# Extra CPPFLAGS necessary to compile on Linux
libEtoileSerialise_CPPFLAGS += -D_GNU_SOURCE=1 -D_XOPEN_SOURCE=600
libEtoileSerialise_OBJCFLAGS += -g -std=c99 -Werror

-include ../GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/subproject.make

-include ../GNUmakefile.postamble
