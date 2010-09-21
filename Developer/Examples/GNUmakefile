PACKAGE_NAME = DeveloperExamples

include $(GNUSTEP_MAKEFILES)/common.make

#
# Variables to turn projects on and off in the build process
# (listed by alphabetical order)
#

-include ../../modules.make

export bookmarkkitexample ?= no
export coreobjectexample ?= yes
export etoilethreadexample ?= yes
export lucenekitexample ?= yes
export ogrekitexample ?= yes
export opmlkitexample ?= no

#
# Projects (listed by dependency order, then alphabetical order)
#

ifeq ($(bookmarkkitexample), yes)	
	SUBPROJECTS += BookmarkKitExample
endif

ifeq ($(coreobjectexample), yes)	
	SUBPROJECTS += CoreObjectExample
endif

ifeq ($(etoilethreadexample), yes)
	SUBPROJECTS += EtoileThreadExample
endif

ifeq ($(lucenekitexample), yes)
	SUBPROJECTS += LuceneKitExample
endif

ifeq ($(ogrekitexample), yes)
	SUBPROJECTS += OgreKitExample
endif

ifeq ($(opmlkitexample), yes)
	SUBPROJECTS += OPMLKitExample
endif

include $(GNUSTEP_MAKEFILES)/aggregate.make
