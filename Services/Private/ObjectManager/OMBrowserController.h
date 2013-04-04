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

/** An abstract controller class that provides access to the editing context. */
@interface OMController : ETController
- (COPersistentRoot *)persistentRootFromSelection;
- (COEditingContext *) editingContext;
@end

/** The controller to supervise the whole ObjectManager window */
@interface OMBrowserController : OMController
{
	ETLayoutItemGroup *contentViewItem;
	ETLayoutItemGroup *sourceListItem;
	ETLayoutItem *viewPopUpItem;
	ETLayoutItem *statusLabelItem;
	id <ETCollection> browsedGroup;

}

/** @taskunit Accessing UI and Model Objects */

@property (nonatomic, retain) ETLayoutItemGroup *contentViewItem;
@property (nonatomic, retain) ETLayoutItemGroup *sourceListItem;
@property (nonatomic, retain) ETLayoutItem *viewPopUpItem;
@property (nonatomic, retain) id <ETCollection> browsedGroup;
@property (nonatomic, readonly) id selectedObject;

/** @taskunit Notifications */

- (void) sourceListSelectionDidChange: (NSNotification *)aNotif;

/** @taskunit Object Insertion and Deletion Actions */

- (IBAction) add: (id)sender;
- (IBAction) addNewObjectFromTemplate: (id)sender;
- (IBAction) addNewTag: (id)sender;
- (IBAction) addNewGroup: (id)sender;
- (IBAction) remove: (id)sender;

/** @taskunit Presentation Actions */

- (IBAction) changePresentationViewFromPopUp: (id)sender;
- (IBAction) changePresentationViewFromMenuItem: (id)sender;
- (IBAction) changeInspectorViewFromMenuItem: (id)sender;

/** @taskunit Other Object Actions */

- (IBAction) doubleClick: (id)sender;
- (IBAction) search: (id)sender;
- (IBAction) open: (id)sender;
- (IBAction) openSelection: (id)sender;
- (IBAction) markVersion: (id)sender;
- (IBAction) revertTo: (id)sender;
- (IBAction) browseHistory: (id)sender;
- (IBAction) export: (id)sender;

@end

/** The subcontroller to supervise the view where the source list selection 
content is presented in an ObjectManager window */
@interface OMBrowserContentController : OMController
{
	id menuProvider;
}

/** @taskunit Persistency Integration */

/** Returns the selected persistent root or the editing context. */
- (id <COPersistentObjectContext>)persistentObjectContext;

/** @taskunit Mutating Content */

- (void) prepareForNewRepresentedObject: (id)anObject;
- (void) addTag: (COGroup *)aTag;

/** @taskunit Actions */

- (IBAction) remove: (id)sender;

@end

/** A category that adds convenient methods for ObjectManager needs */
@interface COEditingContext (OMAdditions)
/** Deletes either persistent roots or just the passed inner objects, based on 
the represented object type (root object or inner object). */
- (void)deleteObjects: (NSSet *)objects;
@end
