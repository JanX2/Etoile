/* 
 *  Dictionary Reader - A Dict client for GNUstep
 *  Copyright (C) 2007 Yen-Ju Chen
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */

#import "Definition.h"
#import "GNUstep.h"

@implementation Definition

- (void) setDatabase: (NSString *) d
{
	ASSIGN(database, d);
}

- (void) setDefinition: (NSString *) d
{
	ASSIGN(definition, d);
}

- (NSString *) database
{
	return database;
}

- (NSString *) definition
{
	return definition;
}

@end

