PACKAGE_NAME = Bundles

include $(GNUSTEP_MAKEFILES)/common.make

#
# Variables check
#

export etoile ?= yes

ifeq ($(etoile), no)

    export desktop-base ?= yes
	#export etoile-extensions ?= no

endif

ifeq ($(etoile), yes)

    export desktop-base ?= yes
	#export etoile-extensions ?= yes

endif

export desktop-base ?= yes

ifeq ($(desktop-base), yes)

    export camaelon ?= yes
    export etoilewildmenus ?= yes

endif

#export etoile-extensions ?= yes

#
# At this time, SQLiteClient is not built by default by being not part of
# etoile-extensions because it introduces too many dependencies.
#

#ifeq ($(etoile-extensions), yes)
#
#    export sqliteclient ?= yes
#
#endif

#
# Subprojects choice
#

ifeq ($(camaelon), yes)
    SUBPROJECTS += Camaelon
endif

ifeq ($(sqliteclient), yes)
    SUBPROJECTS += SQLiteClient
endif

ifeq ($(etoilewildmenus), yes)
    SUBPROJECTS += EtoileWildMenus
endif

include $(GNUSTEP_MAKEFILES)/aggregate.make
