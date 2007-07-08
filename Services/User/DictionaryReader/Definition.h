/* 
 *  Dictionary Reader - A Dict client for GNUstep
 *  Copyright (C) 2007 Yen-Ju Chen
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */

#import <Foundation/Foundation.h>

@interface Definition: NSObject
{
	NSString *database;
	NSString *definition;
}

- (void) setDatabase: (NSString *) database;
- (void) setDefinition: (NSString *) definition;
- (NSString *) database;
- (NSString *) definition;

@end

