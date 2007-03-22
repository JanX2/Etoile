PACKAGE_NAME = PrivateServices

include $(GNUSTEP_MAKEFILES)/common.make

#
# Variables check
#

export etoile ?= yes
export etoile-extensions ?= yes

ifeq ($(etoile), yes)
    
    export workspace ?= yes
    export system ?= yes

endif

ifeq ($(etoile-extensions), yes)

    export azalea ?= yes
    export background ?= yes
    export dock ?= yes

    # Was servicesbar
    export menuserver ?= yes

endif

#
# Subprojects choice
#

ifeq ($(workspace), yes)
    #SUBPROJECTS = Workspace
endif

ifeq ($(azalea), yes)
    SUBPROJECTS += Azalea
endif

ifeq ($(background), yes)
    SUBPROJECTS += AZBackground
endif

ifeq ($(system),yes)
    SUBPROJECTS += System
endif

# MenuServer and AZDock depend on WorkspaceCommKit part of System, so they have
# be built afterwards.

ifeq ($(dock), yes)
    SUBPROJECTS += AZDock
endif

ifeq ($(menuserver),yes)
    SUBPROJECTS += MenuServer
endif

include $(GNUSTEP_MAKEFILES)/aggregate.make
