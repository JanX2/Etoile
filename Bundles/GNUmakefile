#
#	GNUmakefile
#
#	Makefile for Bundles
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
    SUBPROJECTS = Camaelon
endif

ifeq ($(sqliteclient), yes)
    SUBPROJECTS = SQLiteClient
endif

include $(GNUSTEP_MAKEFILES)/aggregate.make
