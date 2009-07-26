include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORK_NAME = EtoilePaint
$(FRAMEWORK_NAME)_VERSION = 0.1

$(FRAMEWORK_NAME)_OBJCFLAGS += -std=c99 
$(FRAMEWORK_NAME)_LIBRARIES_DEPEND_UPON += -lEtoileFoundation -lEtoileUI

$(FRAMEWORK_NAME)_OBJC_FILES = $(wildcard *.m)
$(FRAMEWORK_NAME)_HEADER_FILES = $(wildcard *.h)

include $(GNUSTEP_MAKEFILES)/framework.make
-include ../../etoile.make
-include GNUmakefile.postamble
