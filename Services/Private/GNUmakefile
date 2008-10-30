PACKAGE_NAME = PrivateServices

include $(GNUSTEP_MAKEFILES)/common.make

#
# Variables to turn projects on and off in the build process
# (listed by alphabetical order)
#

-include ../../modules.make

export azalea ?= yes
export azbackground ?= yes
export azdock ?= yes
export azswitch ?= yes
export busy ?= no
export corner ?= yes
export composite ?= no
export idle ?= yes
export login ?= no
export menuserver ?= yes
export scriptservices ?= yes
export system ?= yes

#
# Projects (listed by dependency order, then alphabetical order)
#

ifeq ($(azalea), yes)
    SUBPROJECTS += Azalea
endif

ifeq ($(azbackground), yes)
    SUBPROJECTS += AZBackground
endif

ifeq ($(system),yes)
    SUBPROJECTS += System
endif

# MenuServer and AZDock depend on WorkspaceCommKit part of System, so they have
# be built afterwards.

ifeq ($(azdock), yes)
    SUBPROJECTS += AZDock
endif

ifeq ($(azswitch), yes)
    SUBPROJECTS += AZSwitch
endif

ifeq ($(busy), yes)
    SUBPROJECTS += Busy
endif

ifeq ($(composite), yes)
    SUBPROJECTS += Composite
endif

ifeq ($(corner), yes)
    SUBPROJECTS += Corner
endif

ifeq ($(idle), yes)
    SUBPROJECTS += Idle
endif

ifeq ($(login), yes)
    SUBPROJECTS += Login
endif

ifeq ($(menuserver), yes)
    SUBPROJECTS += MenuServer
endif

ifeq ($(scriptservices), yes)
    SUBPROJECTS += ScriptServices
endif

include $(GNUSTEP_MAKEFILES)/aggregate.make
