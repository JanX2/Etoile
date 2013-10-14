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
#import "OMController.h"

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
- (IBAction) duplicate: (id)sender;

@end

/** A category that adds convenient methods for ObjectManager needs */
@interface COEditingContext (OMAdditions)
/** Deletes either persistent roots or just the passed inner objects, based on 
the represented object type (root object or inner object). */
- (void)deleteObjects: (NSSet *)objects;
@end
