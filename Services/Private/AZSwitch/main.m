/*
 *  AZSwitch - A window switcher for GNUstep
 *  Copyright (C) 2007 Yen-Ju Chen
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */

#import "AZSwitch.h"

int main(int argc, char **argv)
{
	CREATE_AUTORELEASE_POOL(pool);

	// we never show the app icon
	[[NSUserDefaults standardUserDefaults]
		setObject: [NSNumber numberWithBool: YES] forKey: @"GSSuppressAppIcon"];

	[NSApplication sharedApplication];
      
	[NSApp setDelegate: AUTORELEASE([AZSwitch switch])];    
	[NSApp run];   

	DESTROY(pool);

	return 0;
}

