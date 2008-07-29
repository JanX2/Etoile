include $(GNUSTEP_MAKEFILES)/common.make

PACKAGE_NAME = Frameworks

#
# Variables check
#

export etoile ?= yes

ifeq ($(etoile), no)

    export desktop-base ?= yes
    export developer-base ?= yes

endif

ifeq ($(etoile), yes)

    export desktop-base ?= yes
    export etoile-extensions ?= yes

endif

ifeq ($(desktop-base), yes)
    
    export iconkit ?= yes
    export panekit ?= yes
    export addresseskit ?= yes

endif

ifeq ($(etoile-extensions), yes)

    export coreobject ?= yes
    export etoileserialize ?= yes
    export etoilefoundation ?= yes
    export etoileui ?= yes
    export distributedview ?= yes
    export ogrekit ?= yes
    export lucenekit ?= yes
    export servicesbarkit ?= yes
    #export rsskit ?= yes
    export xwindowserverkit ?= yes
    export popplerkit ?= yes
    export systemconfig ?= yes
	export mediakit ?= yes
    
endif

export developer-base ?= yes

ifeq ($(developer-base), yes)
    
    export unitkit ?= yes

endif

ifeq ($(test), yes)
    
    export unitkit ?= yes

endif
  
#
# Subprojects choice
#

#
# developer-base
#

# We need to build UnitKit first because other frameworks may depend on it 
# (with 'make test=yes').
ifeq ($(unitkit), yes)
   SUBPROJECTS += UnitKit 
endif

#
# etoile-extensions
#

# We need to build CoreObject, EtoileFoundation and EtoileUI first because 
# other frameworks depends on it.
ifeq ($(coreobject), yes)
    #SUBPROJECTS += CoreObject
endif

ifeq ($(etoilefoundation), yes)
    SUBPROJECTS += EtoileFoundation
endif

ifeq ($(etoileserialize), yes)
    SUBPROJECTS += EtoileSerialize
endif

ifeq ($(etoileui), yes)
    SUBPROJECTS += EtoileUI
endif

# Takes care to build EtoileUI before DistributedView, because DistributedView 
# depends on it.
ifeq ($(distributedview), yes)
    SUBPROJECTS += DistributedView
endif

# We need to build OgreKit before LuceneKit, because LuceneKit depends on it.
ifeq ($(ogrekit), yes)
   SUBPROJECTS += OgreKit
endif

ifeq ($(lucenekit), yes)
   SUBPROJECTS += LuceneKit
endif

ifeq ($(servicesbarkit), yes)
  ifneq ($(FOUNDATION_LIB), apple)
    # do not compile for apple
    #SUBPROJECTS += ServicesBarKit
  endif
endif

ifeq ($(rsskit), yes)
   SUBPROJECTS += RSSKit
endif

ifeq ($(xwindowserverkit), yes)
   SUBPROJECTS += XWindowServerKit
endif

ifeq ($(popplerkit), yes)
   SUBPROJECTS += PopplerKit
endif

#
# desktop-base
#

ifeq ($(iconkit), yes)
   SUBPROJECTS += IconKit
endif

ifeq ($(panekit), yes)
   SUBPROJECTS += PaneKit
endif

ifeq ($(addresseskit), yes)
   SUBPROJECTS += AddressesKit
endif

ifeq ($(systemconfig), yes)
   SUBPROJECTS += SystemConfig
endif

ifeq ($(mediakit), yes)
   SUBPROJECTS += MediaKit
endif

include $(GNUSTEP_MAKEFILES)/aggregate.make
