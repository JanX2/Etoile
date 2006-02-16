PACKAGE_NAME = Services

include $(GNUSTEP_MAKEFILES)/common.make

#
# Variables check
#

export etoile ?= yes

ifeq ($(etoile), no)
	
	export etoile-extensions ?= no

endif

ifeq ($(etoile), yes)

	export etoile-extensions ?= yes

endif

export user-base ?= yes

#
# Subprojects choice
#

SUBPROJECTS = Private User

include $(GNUSTEP_MAKEFILES)/aggregate.make
