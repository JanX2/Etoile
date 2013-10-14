/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  October 2013
	License:  Modified BSD  (see COPYING)
 */

#import "COObject+ObjectManager.h"

@implementation COObject (ObjectManager)

- (NSDate *) modificationDate
{
	return [[self persistentRoot] modificationDate];
}

- (NSDate *) creationDate
{
	return [[self persistentRoot] creationDate];
}

@end
