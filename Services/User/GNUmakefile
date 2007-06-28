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
    export addressmanager ?= yes
    export chatclient ?= yes
    export dictionary ?= yes
    export fontmanager ?= yes
    export grr ?= yes
    export terminal ?= yes
    export typewriter ?= yes
    export vindaloo ?= yes

endif

ifeq ($(user-base), no)

    export installer ?= no
    export look-and-behavior ?= no
    export hardware ?= no
    export addressmanager ?= no
    export chatclient ?= no
    export dictionary ?= no
    export fontmanager ?= no
    export grr ?= no
    export terminal ?= no
    export typewriter ?= no
    export vindaloo ?= no

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

ifeq ($(addressmanager), yes)
	SUBPROJECTS += AddressManager
endif

ifeq ($(chatclient), yes)
	SUBPROJECTS += Jabber
endif

ifeq ($(dictionary), yes)
	SUBPROJECTS += DictionaryReader
endif

ifeq ($(fontmanager), yes)
	SUBPROJECTS += FontManager
endif

ifeq ($(grr), yes)
	SUBPROJECTS += Grr
endif

ifeq ($(terminal), yes)
	SUBPROJECTS += TermX
endif

ifeq ($(typewriter), yes)
	SUBPROJECTS += Typewriter
endif

ifeq ($(vindaloo), yes)
	SUBPROJECTS += Vindaloo
endif

include $(GNUSTEP_MAKEFILES)/aggregate.make
