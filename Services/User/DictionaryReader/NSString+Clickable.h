/*  -*-objc-*-
 *
 *  Dictionary Reader - A Dict client for GNUstep
 *  Copyright (C) 2006 Guenther Noack
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */

#import <Foundation/Foundation.h>

extern NSString* WordClickedNotificationType;

@interface NSString (Clickable)

-(void) click;

@end
