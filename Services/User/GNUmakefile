PACKAGE_NAME = UserServices

include $(GNUSTEP_MAKEFILES)/common.make

#
# Variables to turn projects on and off in the build process
# (listed by alphabetical order)
#

-include ../../modules.make

export addressmanager ?= yes
export calc ?= no
export codeeditor ?= no
export dictionaryreader ?= yes
export fontmanager ?= yes
export grr ?= no
export hardware ?= yes
export installer ?= no
export jabber ?= yes
export lookandbehavior ?= yes
export melodie ?= yes
export microblogger ?= no
export newsstand ?= no
export sketch ?= no
export termx ?= no
export typewriter ?= yes
export vindaloo ?= yes
export workflow ?= no

#
# Projects (listed by dependency order, then alphabetical order)
#

ifeq ($(addressmanager), yes)
	SUBPROJECTS += AddressManager
endif

ifeq ($(calc), yes)
	SUBPROJECTS += Calc
endif

ifeq ($(dictionaryreader), yes)
	SUBPROJECTS += DictionaryReader
endif

ifeq ($(codeeditor), yes)
	SUBPROJECTS += CodeEditor
endif

ifeq ($(fontmanager), yes)
	SUBPROJECTS += FontManager
endif

ifeq ($(grr), yes)
	SUBPROJECTS += Grr
endif

ifeq ($(hardware), yes)
	SUBPROJECTS += Hardware
endif

ifeq ($(installer), yes)
	SUBPROJECTS += Installer
endif

ifeq ($(jabber), yes)
	SUBPROJECTS += Jabber
endif

ifeq ($(lookandbehavior), yes)
	SUBPROJECTS += LookAndBehavior
endif

ifeq ($(melodie), yes)
	SUBPROJECTS += Melodie
endif

ifeq ($(microblogger), yes)
	SUBPROJECTS += Microblogger
endif

ifeq ($(newsstand), yes)
	SUBPROJECTS += NewsStand
endif

ifeq ($(sketch), yes)
	SUBPROJECTS += Sketch
endif

ifeq ($(termx), yes)
	SUBPROJECTS += TermX
endif

ifeq ($(typewriter), yes)
	SUBPROJECTS += Typewriter
endif

ifeq ($(vindaloo), yes)
	SUBPROJECTS += Vindaloo
endif

ifeq ($(workflow), yes)
	SUBPROJECTS += Workflow
endif

include $(GNUSTEP_MAKEFILES)/aggregate.make
