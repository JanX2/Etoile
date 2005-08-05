#
#	GNUmakefile
#
#	Makefile for Frameworks
#
#	Copyright (C) 2005 Quentin Mathe <qmathe@club-internet.fr>
#
#	This Makefile is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public License
#	as published by the Free Software Foundation; either version 2
#	of the License, or (at your option) any later version.
#
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#	See the GNU General Public License for more details.
#
#	You should have received a copy of the GNU General Public License
#	along with this program; if not, write to:
#
#		Free Software Foundation, Inc.
#		59 Temple Place - Suite 330
#		Boston, MA  02111-1307, USA
#

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
# ExtendedWorkspaceKit, PreferencesKit depend on it.
ifeq ($(etoileextensionskit), yes)
    SUBPROJECTS += EtoileExtensionsKit
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
