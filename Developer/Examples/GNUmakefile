#
#    Makefile for Etoile Developer Examples
#

PACKAGE_NAME = DeveloperExamples

include $(GNUSTEP_MAKEFILES)/common.make

#
# Variables check
#

export etoile ?= yes
export developer-base ?= yes

ifeq ($(developer-base), yes)

	export examples ?= yes

endif

ifeq ($(developer-base), no)

	export examples ?= no

endif

#
# Subprojects choice
# 

ifeq ($(examples), yes)	
	SUBPROJECTS = DistributedViewExample LuceneKitExample \
PreferencesKitExample OgreKitExample BookmarkKitExample #IoExample 

ifeq ($sqlliteclient, yes)
    SUBPROJECTS += SQLLiteClientExample
endif

endif

include $(GNUSTEP_MAKEFILES)/aggregate.make
