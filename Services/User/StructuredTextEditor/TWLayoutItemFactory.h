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

@class TWEditorController;

@interface TWLayoutItemFactory : ETLayoutItemFactory
{

}

/** @taskunit Default Sizes */

- (CGFloat) defaultInspectorWidth;

/** @taskunit Main UI */

- (ETLayoutItemGroup *) editorWithRepresentedObject: (id)anObject editingContext: (COEditingContext *)aContext;
- (ETLayoutItemGroup *) bodyWithRepresentedObject: (id <ETCollection>)aGroup controller: (id)aController;
- (ETLayoutItem *) viewPopUpWithController: (id)aController;
- (ETLayoutItemGroup *) topBarWithController: (ETController *)aController;
- (ETLayoutItemGroup *) contentViewWithRepresentedObject: (id)anObject controller: (id)aController;

/** @taskunit Accessory UI */

- (ETLayoutItemGroup *) inspectorWithObject: (id)anObject size: (NSSize)aSize controller: (id)aController;

@end

@interface ETApplication (TypeWriter)
/** Returns the visible View menu if there is one already inserted in the
 menu bar, otherwise builds a new instance and returns it. */
- (NSMenuItem *) viewMenuItem;
@end
