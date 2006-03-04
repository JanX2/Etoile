PACKAGE_NAME = PrivateServices

include $(GNUSTEP_MAKEFILES)/common.make

#
# Variables check
#

export etoile ?= yes
export etoile-extensions ?= yes

ifeq ($(etoile), yes)
    
    export workspace ?= yes

endif

ifeq ($(etoile-extensions), yes)

    export menuserver ?= yes # Was servicesbar

endif

#
# Subprojects choice
#

ifeq ($(workspace), yes)
    #SUBPROJECTS = Workspace
endif

ifeq ($(menuserver), yes)
    SUBPROJECTS += MenuServer
endif

include $(GNUSTEP_MAKEFILES)/aggregate.make
