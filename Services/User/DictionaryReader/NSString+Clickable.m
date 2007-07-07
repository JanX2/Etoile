/*  -*-objc-*-
 *
 *  Dictionary Reader - A Dict client for GNUstep
 *  Copyright (C) 2006 Guenther Noack
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */

#import "NSString+Clickable.h"

NSString* WordClickedNotificationType = @"WordClickedNotificationType";

@implementation NSString (Clickable)

- (void) click
{
	[[NSNotificationCenter defaultCenter]
		postNotificationName: WordClickedNotificationType
		object: self];
}

@end

