#
#	GNUmakefile
#
#	Makefile for Camaelon
#
#	Copyright (C) 2004 Nicolas Roard <nicolas@roard.com>
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

ADDITIONAL_OBJCFLAGS = -Wno-import #-g -Wall -O2

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

#
# Main
#
PACKAGE_NAME = Camaelon
BUNDLE_NAME = Camaelon
BUNDLE_EXTENSION = .themeEngine
VERSION = 2

Camaelon_PRINCIPAL_CLASS = Camaelon

#
# Class files
#
Camaelon_OBJC_FILES = \
		Camaelon.m \
		GraphicToolbox.m \
		GSDrawFunctions.m \
		CLImage.m \
		CLCompositor.m \
		CLBoxCompositor.m \
		CLHBoxCompositor.m \
		CLVBoxCompositor.m \
		CLCache.m \
		ImageProvider.m
#
# Other class files
#
Camaelon_OBJC_FILES += \
		NSBezierPath+round.m \
		NSColor.m \
		NSTabViewItem.m \
		#NSWindow.m

#
# View class files
#
Camaelon_OBJC_FILES += \
		NSClipView.m \
		GSWindowDecoratorView.m \
		NSMenuView.m \
		NSSplitView.m \
		NSOutlineView.m \
		NSScrollView.m \
		NSTabView.m \
		NSTableView.m \
		NSTableHeaderView.m \
		GSTableCornerView.m \
		#NSView.m 

#
# Other View class files
#
Camaelon_OBJC_FILES += \
		NSBrowser.m \
		NSBox.m \
		NSColorWell.m \
		NSMatrix.m \
		GSBrowserMatrix.m \
		NSProgressIndicator.m \
		NSSlider.m \
		NSScroller.m
		
#
# Other Cell classes
#
Camaelon_OBJC_FILES += \
		NSCell.m \
		NSButtonCell.m \
		NSBrowserCell.m \
		GSBrowserTitleCell.m \
		NSFormCell.m \
		NSMenuItemCell.m \
		NSPopUpButtonCell.m \
		NSComboBoxCell.m \
		NSSliderCell.m \
		NSTableHeaderCell.m \
		NSTextFieldCell.m

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/bundle.make

-include GNUmakefile.postamble
