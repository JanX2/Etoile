#
#	GNUmakefile
#
#	Main makefile for Etoile Workspace
#
#	Copyright (C) 2004 Quentin Mathe <qmathe@club-internet.fr>
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

ADDITIONAL_OBJCFLAGS = -Wno-import

PACKAGE_NAME = Workspace

#
# Main application
#	
APP_NAME=		Workspace
VERSION=		0.1

Workspace_SUBPROJECTS = FilieCore
Workspace_PRINCIPAL_CLASS=	NSApplication
Workspace_APPLICATION_ICON=

Workspace_LIB_DIRS = -L../$(GNUSTEP_LIBRARIES_ROOT)
Workspace_GUI_LIBS = -lExtendedWorkspaceKit
#FRAMEWORKS= ExtendedWorkspaceKit

#
# Resource files
#
Workspace_MAIN_MODEL_FILE=	Workspace.gorm
Workspace_RESOURCE_FILES= \
	WorkspaceInfo.plist \
	Workspace.gorm \
	WorkspaceWindow.gorm

Workspace_LOCALIZED_RESOURCE_FILES=

#
# Languages we're localized for
#
Workspace_LANGUAGES= \
	English

#
# Header files
#
Workspace_HEADER_FILES_DIR = . ./FilieCore

Workspace_HEADERS= \
	WorkspaceController.h \
	WkContextWindowController.h \
	WkContextViewController.h \
        WkContextFolderIconView.h \
	WkContextTableViewController.h \
	ViewerController.h

#
# Class files
#
Workspace_OBJC_FILES= \
	WorkspaceController.m \
	WkContextWindowController.m \
	WkContextViewController.m \
	WkContextFolderIconViewController.m \
	WkContextTableViewController.m \
	main.m

#
# C files
#
Preferences_C_FILES=

-include GNUmakefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make

-include GNUmakefile.postamble
