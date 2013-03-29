/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2011
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileFoundation/EtoileFoundation.h>
#ifndef GNUSTEP
#import <EtoileFoundation/GNUstep.h>
#endif
#import <CoreObject/CoreObject.h>
#import <EtoileUI/EtoileUI.h>

@class OMLayoutItemFactory;

@interface OMAppController : ETDocumentController
{
	OMLayoutItemFactory *itemFactory;
	NSMutableSet *openedGroups;
	COCustomTrack *mainUndoTrack;
}

- (NSArray *) sourceListGroups;

- (IBAction) browseMainGroup: (id)sender;
- (IBAction) undo: (id)sender;
- (IBAction) redo: (id)sender;

- (void) buildCoreObjectGraphDemo;

@end

// TODO: Allow icon customization without subclassing... For COCollection at least.
@interface OMGroup : COGroup
- (NSImage *) icon;
@end

@interface OMSmartGroup : COSmartGroup
- (NSImage *) icon;
@end
