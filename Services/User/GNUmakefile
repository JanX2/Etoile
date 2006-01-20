PACKAGE_NAME = UserServices

include $(GNUSTEP_MAKEFILES)/common.make

#
# Variables check
#

export etoile ?= yes
export user-base ?= yes

ifeq ($(user-base), yes)

    export installer ?= yes
    export look-and-behavior ?= yes
    export hardware ?= yes

endif

ifeq ($(user-base), no)

    export installer ?= no
    export look-and-behavior ?= no
    export hardware ?= no

endif

#
# Subprojects choice
# 

ifeq ($(installer), yes)
	SUBPROJECTS = #Installer
endif

ifeq ($(look-and-behavior), yes)
	SUBPROJECTS += LookAndBehavior
endif

ifeq ($(hardware), yes)
	SUBPROJECTS += Hardware
endif

include $(GNUSTEP_MAKEFILES)/aggregate.make
