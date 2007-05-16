//
//  main.m
//  TestApp
//
//  Created by David Chisnall on 23/02/2007.
//  Copyright __MyCompanyName__ 2007. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
	/* Don't display an icon for this application, since it is supposed not to
	 * have a GUI at all.  It uses AppKit solely in order to be able to get an
	 * X11 Window.
	 */
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES]
	                                          forKey: @"GSSuppressAppIcon"];
	[pool release];
	return NSApplicationMain(argc,  (const char **) argv);
}
