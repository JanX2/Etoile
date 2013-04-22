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
@interface TWEditorController : ETController
{
	ETLayoutItemGroup *contentViewItem;
	ETLayoutItemGroup *sourceListItem;
	ETLayoutItem *viewPopUpItem;
	ETLayoutItem *statusLabelItem;
}

/** @taskunit Accessing UI and Model Objects */

@property (nonatomic, retain) ETLayoutItemGroup *contentViewItem;
@property (nonatomic, readonly) ETLayoutItemGroup *contentViewWrapperItem;
@property (nonatomic, retain) ETLayoutItemGroup *sourceListItem;
@property (nonatomic, retain) ETLayoutItem *viewPopUpItem;

/** @taskunit Selection */

@property (nonatomic, readonly) NSArray *selectedObjectInContentView;
@property (nonatomic, readonly) NSArray *selectedObjectsInSourceList;

/** @taskunit Notifications */

- (void) sourceListSelectionDidChange: (NSNotification *)aNotif;

/** @taskunit Presentation */

@property (assign, nonatomic) BOOL isInspectorHidden;

- (void) showInspector;
- (void) hideInspector;

/** @taskunit Object Insertion and Deletion Actions */

- (IBAction) add: (id)sender;
- (IBAction) insert: (id)sender;
- (IBAction) remove: (id)sender;

/** @taskunit Presentation Actions */

- (IBAction) changePresentationViewFromPopUp: (id)sender;
- (IBAction) changePresentationViewFromMenuItem: (id)sender;
- (IBAction) changeInspectorViewFromMenuItem: (id)sender;
- (IBAction) toggleInspector: (id)sender;

/** @taskunit Other Object Actions */

- (IBAction) search: (id)sender;
- (IBAction) open: (id)sender;
- (IBAction) browseHistory: (id)sender;

@end
