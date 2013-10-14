/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  October 2013
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileFoundation/EtoileFoundation.h>
#ifndef GNUSTEP
#import <EtoileFoundation/GNUstep.h>
#endif
#import <CoreObject/CoreObject.h>

/** 
 * These additional properties are registered in the metamodel when 
 * OMModelFactory is initialized.
 */
@interface COObject (ObjectManager)
@property (nonatomic, readonly) NSDate *modificationDate;
@property (nonatomic, readonly) NSDate *creationDate;
@end
