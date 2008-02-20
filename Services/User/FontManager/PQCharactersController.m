/*
 * PQCharactersController.m - Font Manager
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 12/02/07
 * License: 3-Clause BSD license (see file COPYING)
 */


#include "PQCharactersController.h"
#import "PQCompat.h"


@implementation PQCharactersController

- (id) init
{
	[super init];
	
	fontName = [[NSString alloc] init];
	
	RETAIN(fontName);
	
	return self;
}

- (void) dealloc
{
	RELEASE(fontName);
	
	[super dealloc];
}

- (void) changeCharSize: (id)sender
{
  [charView setFontSize: [sender intValue]];
}

- (void) setFont: (NSString *)newFontName
{
	ASSIGN(fontName, newFontName);
	
	[charView setFont: fontName];
}

- (NSString *) font
{
	return fontName;
}

@end
