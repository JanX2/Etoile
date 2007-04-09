/*
 * WFObjectDrawing.h - Workflow
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 04/07/07
 * License: Modified BSD license (see file COPYING)
 */


#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "WFObject.h"


@interface WFObject (WFObjectDrawing)

- (NSRect) rect;
- (NSDictionary *)layout;
- (void) draw;

@end
