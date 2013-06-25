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

@class OMBrowserController;

@interface OMLayoutItemFactory : ETLayoutItemFactory
{

}

/** @taskunit Default Sizes */

- (CGFloat) defaultTagFilterEditorHeight;
- (CGFloat) defaultInspectorWidth;

/** @taskunit Main UI */

- (ETLayoutItemGroup *) browserWithGroup: (id <ETCollection>)aGroup editingContext: (COEditingContext *)aContext;
- (ETLayoutItemGroup *) browserBodyWithGroup: (id <ETCollection>)aGroup controller: (id)aController;
- (ETLayoutItem *) viewPopUpWithController: (OMBrowserController *)aController;
- (ETLayoutItemGroup *) browserTopBarWithController: (id)aController;
- (ETLayoutItemGroup *) sourceListWithGroup: (id <ETCollection>)aGroup controller: (id)aController;
- (ETLayoutItemGroup *) contentViewWithGroup: (id <ETCollection>)aGroup controller: (id)aController;

/** @taskunit Accessory UI */

/** Returns a UI to select the tags used to filter the content. This is a view 
to manage both the tags in a global way and the filtering of the content 
(derived from the selection).
 
Selected tags represent the tags used to filter the content, non-selected 
tags represent other choices you can make to filter the content. The active 
selection can be extended or reduced by using the usual selection modifier keys.
 
For now, all the tags are presented in a single view. In future, the view will 
be split in two parts, a scope bar to select one or more active tag groups and 
a tag editor view presenting the tags from all the selected active tag groups. 
So the visible tags are the union of the tags in the selected tag groups of the 
scope bar above. 
 
Both selected and non-selected tags can be edited with a double-click on them, 
this renames the tag (and concerns all the objects in -[COTag content]).
 
If the user clicks in the background, a tag name can be typed. If the tag name 
is not in use, a new tag is added to the store (instantiated from the local 
controller templates), otherwise the editing is cancelled. For a tag name in use, 
the field editor doesn't validate the name (not yet done). For an empty name, 
no tag is added, the editing is just ended. */
- (ETLayoutItemGroup *) tagFilterEditorWithTagLibrary: (COTagLibrary *)aTagLibrary size: (NSSize)aSize controller: (id)aController;
- (ETLayoutItemGroup *) inspectorWithObject: (id)anObject size: (NSSize)aSize controller: (id)aController;

@end

@interface ETApplication (ObjectManager)
/** Returns the visible Object menu if there is one already inserted in the 
menu bar, otherwise builds a new instance and returns it. */
- (NSMenuItem *) objectMenuItem;
/** Returns the visible View menu if there is one already inserted in the
 menu bar, otherwise builds a new instance and returns it. */
- (NSMenuItem *) viewMenuItem;
@end
