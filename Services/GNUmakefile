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

PACKAGE_NAME = Services

include $(GNUSTEP_MAKEFILES)/common.make

#
# Variables cehck
#

export etoile ?= yes

ifeq ($(etoile), no)
	
	export etoile-extensions ?= no

endif

ifeq ($(etoile), yes)

	export etoile-extensions ?= yes

endif

export developer-base ?= yes

#
# Subprojects choice
#

SUBPROJECTS = Developer Private

include $(GNUSTEP_MAKEFILES)/aggregate.make
