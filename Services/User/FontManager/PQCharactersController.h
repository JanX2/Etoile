/*
 * PQCharactersController.h - Font Manager
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 12/02/07
 * License: 3-Clause BSD license (see file COPYING)
 */


#import <AppKit/AppKit.h>
#import "PQCharacterView.h"


@interface PQCharactersController : NSObject
{
  PQCharacterView *charView;
  NSSlider *charSizeSlider;
	
	NSString *fontName;
}

- (void) changeCharSize: (id)sender;
- (void) setFont: (NSString *)fontName;
- (NSString *) font;

@end
