/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2013
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileFoundation/EtoileFoundation.h>
#ifndef GNUSTEP
#import <EtoileFoundation/GNUstep.h>
#endif
#import <CoreObject/CoreObject.h>
#import <EtoileText/EtoileText.h>
#import <EtoileUI/EtoileUI.h>
#import <EtoileUI/CoreObjectUI.h>

@class TWLayoutItemFactory;

/** The controller to supervise the entire application */
@interface TWAppController : ETDocumentController
{
	TWLayoutItemFactory *itemFactory;
	NSMutableSet *openedGroups;
	COCustomTrack *mainUndoTrack;
	NSString *currentPresentationTitle;
}

/** @taskunit Menu Management */

/**
 * The checkmarked menu items among the various presentations (icon, list etc.) 
 * in the View menu.
 *
 * As an alternative, we could have a method -[ETController becomeActive] 
 * invoked one every first responder change to memorize the current presentation 
 * title in TWEditorController directly.
 */
@property (nonatomic, retain) NSString *currentPresentationTitle;

/** @taskunit Actions */

- (IBAction) undo: (id)sender;
- (IBAction) redo: (id)sender;

@end
