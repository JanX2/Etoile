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

ifeq ($(system),yes)
    SUBPROJECTS += System
endif

# MenuServer depends on WorkspaceCommKit part of System, so it has to be built
# afterwards.
ifeq ($(menuserver),yes)
    SUBPROJECTS += MenuServer
endif

include $(GNUSTEP_MAKEFILES)/aggregate.make
