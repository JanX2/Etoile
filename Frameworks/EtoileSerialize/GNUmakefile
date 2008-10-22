include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORK_NAME = EtoileSerialize
BUNDLE_NAME = ${FRAMEWORK_NAME}
DOCUMENT_NAME = ${FRAMEWORK_NAME}

${FRAMEWORK_NAME}_SUBPROJECTS = Sources

${FRAMEWORK_NAME}_HEADER_FILES_DIR = Headers

${FRAMEWORK_NAME}_LDFLAGS += -lEtoileFoundation
${FRAMEWORK_NAME}_LIBRARIES_DEPEND_UPON += -lEtoileFoundation

${FRAMEWORK_NAME}_HEADER_FILES = \
				   EtoileSerialize.h\
				   ESProxy.h\
				   ETUtility.h\
				   ETDeserializerBackend.h\
				   ETDeserializerBackendBinary.h\
				   ETSerializerBackend.h\
				   ETSerializerBackendBinary.h\
				   ETSerializerBackendXML.h\
				   ETSerializerNullBackend.h\
				   ETDeserializer.h\
				   ETSerializer.h\
				   ETSerializerBackendExample.h\
				   ETObjectStore.h


${DOCUMENT_NAME}_AGSDOC_FILES = $(addprefix Headers/, ${EtoileSerialize_HEADER_FILES})
${DOCUMENT_NAME}_AGSDOC_FLAGS += -MakeFrames YES

OBJCFLAGS += -std=c99 -Wall -W -Wunreachable-code -Winline -Werror -Wno-unused -Wno-format -g
LDFLAGS += -g

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
-include ../../etoile.make
-include etoile.make

ifeq ($(test), yes)
include $(GNUSTEP_MAKEFILES)/bundle.make
else
include $(GNUSTEP_MAKEFILES)/framework.make
endif

#include $(GNUSTEP_MAKEFILES)/documentation.make

-include GNUmakefile.postamble

test:
	${MAKE} test=yes && ukrun -q ${BUNDLE_NAME}.bundle
