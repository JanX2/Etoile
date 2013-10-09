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
#import <EtoileUI/CoreObjectUI.h>

@class OMLayoutItemFactory;

/** The controller to supervise the entire ObjectManager application */
@interface OMAppController : ETDocumentController
{
	COEditingContext *editingContext;
	OMLayoutItemFactory *itemFactory;
	NSMutableSet *openedGroups;
	COUndoTrack *mainUndoTrack;
	NSString *currentPresentationTitle;
}

/** @taskunit Persistency */

@property (nonatomic, readonly) COEditingContext *editingContext;

/** @taskunit Menu Management */

/**
 * The checkmarked menu items among the various presentations (icon, list etc.) 
 * in the View menu.
 *
 * As an alternative, we could have a method -[ETController becomeActive] 
 * invoked one every first responder change to memorize the current presentation 
 * title in OMBrowserController directly.
 */
@property (nonatomic, retain) NSString *currentPresentationTitle;

/** @taskunit Actions */

- (IBAction) browseMainGroup: (id)sender;
- (IBAction) undo: (id)sender;
- (IBAction) redo: (id)sender;

@end
