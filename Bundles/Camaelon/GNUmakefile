ETOILE_CORE_MODULE = YES

include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_OBJCFLAGS = -Wno-import #-g -Wall -O2

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
		CamaelonDrawFunctions.m \
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
		NSWindow.m

#
# View class files
#
Camaelon_OBJC_FILES += \
		NSClipView.m \
		NSMenuView.m \
		NSScrollView.m \
		NSSplitView.m \
		NSOutlineView.m \
		NSTabView.m \
		NSTableView.m \
		NSTableHeaderView.m \
		GSTableCornerView.m \
	        GSToolbar.m	
#		GSWindowDecoratorView.m \
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

Camaelon_RESOURCE_FILES += \
		Nesedah.theme \
		Narcissus.theme


-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/bundle.make
-include ../../etoile.make

-include GNUmakefile.postamble
