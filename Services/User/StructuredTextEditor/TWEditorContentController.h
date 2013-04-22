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
#import <EtoileUI/EtoileUI.h>
#import <EtoileUI/CoreObjectUI.h>

/** The controller to supervise the whole ObjectManager window */
@interface TWEditorContentController : ETController
{

}

/** @taskunit Selection */

@property (nonatomic, readonly) NSArray *selectedObjects;

/** @taskunit Notifications */

- (void) selectionDidChange: (NSNotification *)aNotif;

/** @taskunit Object Insertion and Deletion Actions */

- (IBAction) add: (id)sender;

/** @taskunit Other Object Actions */

- (IBAction) search: (id)sender;

@end
