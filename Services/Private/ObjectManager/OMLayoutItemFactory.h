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
