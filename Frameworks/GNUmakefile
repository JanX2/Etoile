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

ifeq ($(etoile), no)

    export desktop-base ?= yes
    export etoile-extensions ?= yes

endif

ifeq ($(desktop-base), yes)
    
    export bookmarkkit ?= yes
    export iconkit ?= yes
    export preferenceskit ?= yes

endif

ifeq ($(etoile-extensions), yes)
    
    export etoileextensionskit ?= yes
    export ogrekit ?= yes
    export lucenekit ?= yes
    export servicesbarkit ?= yes
    export extendedworkspacekit ?= yes 
    export trackerkit ?= yes

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

# We need to build EtoileExtensionsKit first because other frameworks like 
# ExtendedWorkspaceKit, PreferencesKit depends on it.
ifeq ($(etoileextensionskit), yes)
    SUBPROJECTS += EtoileExtensionsKit
endif

# We need to build OgreKit before LuceneKit, because LuceneKit depends on it.
ifeq ($(ogrekit), yes)
   SUBPROJECTS += OgreKit
endif

ifeq ($(lucenekit), yes)
   SUBPROJECTS += LuceneKit
endif

ifeq ($(servicesbarkit), yes)
   SUBPROJECTS += ServicesBarKit
endif

ifeq ($(extendedworkspacekit), yes)
   SUBPROJECTS += ExtendedWorkspaceKit
endif

ifeq ($(trackerkit), yes)
   #SUBPROJECTS += TrackerKit
endif

#
# desktop-base
#

ifeq ($(bookmarkkit), yes)
   SUBPROJECTS += BookmarkKit
endif

ifeq ($(iconkit), yes)
   SUBPROJECTS += IconKit
endif

ifeq ($(preferenceskit), yes)
   SUBPROJECTS += PreferencesKit
endif

include $(GNUSTEP_MAKEFILES)/aggregate.make
