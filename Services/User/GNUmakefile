PACKAGE_NAME = UserServices

include $(GNUSTEP_MAKEFILES)/common.make

#
# Variables to turn projects on and off in the build process
# (listed by alphabetical order)
#

-include ../../modules.make

export addressmanager ?= yes
export codeeditor ?= no
export dictionaryreader ?= yes
export fontmanager ?= yes
export hardware ?= yes
export lookandbehavior ?= yes
export melodie ?= yes
export microblog ?= yes
export newsstand ?= no
export stepchat ?= yes
export termx ?= no
export typewriter ?= yes
export vindaloo ?= yes

#
# Projects (listed by dependency order, then alphabetical order)
#

ifeq ($(addressmanager), yes)
	SUBPROJECTS += AddressManager
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

ifeq ($(hardware), yes)
	SUBPROJECTS += Hardware
endif

ifeq ($(lookandbehavior), yes)
	SUBPROJECTS += LookAndBehavior
endif

ifeq ($(melodie), yes)
	SUBPROJECTS += Melodie
endif

ifeq ($(microblog), yes)
	SUBPROJECTS += MicroblogAtom Microblogger
endif

ifeq ($(newsstand), yes)
	SUBPROJECTS += NewsStand
endif

ifeq ($(stepchat), yes)
	SUBPROJECTS += StepChat
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

include $(GNUSTEP_MAKEFILES)/aggregate.make
