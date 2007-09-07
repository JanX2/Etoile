/*
	NSFileManager+IconKit.h

	NSFileManager extension with convenient methods
	
	Copyright (C) 2004  Quentin Mathe <qmathe@club-internet.fr>	                   

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2004

    This application is free software; you can redistribute it and/or 
    modify it under the terms of the 3-clause BSD license. See COPYING.
*/

#import <Foundation/Foundation.h>

@interface NSFileManager (IconKit)

- (BOOL) buildDirectoryStructureForPath: (NSString *)path;
- (BOOL) checkWithEventuallyCreatingDirectoryAtPath: (NSString *)path;

@end
