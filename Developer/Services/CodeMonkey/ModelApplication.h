/*
   Copyright (C) 2010 Nicolas Roard <nicolas@roard.com>

   This application is free software; you can redistribute it and/or
   modify it under the terms of the MIT license. See COPYING.
*/

#import <Foundation/Foundation.h>

@interface ModelApplication : NSObject
{
	NSString* name;
	NSString* path;
	NSMutableArray* nibs;
	int mainNibIndex;
}

- (void) addNib;
- (void) removeNibAtIndex: (int) index;
- (void) renameNibAtIndex: (int) index withName: (NSString*) name;
- (void) editNibAtIndex: (int) index;
- (NSArray*) nibs;
- (void) ensureExists;
- (void) makeMainNibAtIndex: (int) index;

- (void) setPath: (NSString*) aPath;
- (void) setName: (NSString*) aName;

- (void) generateBundleExecutable;
- (void) generateBundleClasses;
- (void) generateBundleInfosGNUstep;
- (void) generateAppBundle;
- (void) generateNibs;
@end
