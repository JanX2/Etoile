/*
	PKBundleController.m

	Bundle manager class and protocol

	Copyright (C) 2001 Dusk to Dawn Computing, Inc. 
	              2004 Quentin Mathe

	Author: Jeff Teunissen <deek@d2dc.net>
	        Quentin Mathe <qmathe@club-internet.fr>

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License as
	published by the Free Software Foundation; either version 2 of
	the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

	See the GNU General Public License for more details.

	You should have received a copy of the GNU General Public
	License along with this program; if not, write to:

		Free Software Foundation, Inc.
		59 Temple Place - Suite 330
		Boston, MA  02111-1307, USA
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "PKBundleController.h"


/*
 * PKBundleController extensions
 */

@interface PKBundleController (Private)

- (NSArray *) bundlesWithExtension: (NSString *)extension inPath: (NSString *)path;

@end

@implementation PKBundleController (Private)

- (NSArray *) bundlesWithExtension: (NSString *)extension inPath: (NSString *)path
{
	NSMutableArray	*bundleList = [[NSMutableArray alloc] initWithCapacity: 10];
	NSEnumerator	*enumerator;
	NSFileManager	*fm = [NSFileManager defaultManager];
	NSString		*dir;
	BOOL			isDir;

	/* Ensure path exists, and is a directory. */
	if ([fm fileExistsAtPath: path isDirectory: &isDir] == NO)
		return nil;

	if (isDir == NO)
		return nil;

	/* Scan for bundles matching the extension in the dir. */
	enumerator = [[fm directoryContentsAtPath: path] objectEnumerator];
	while ((dir = [enumerator nextObject])) 
	{
		if ([[dir pathExtension] isEqualToString: extension])
			[bundleList addObject: [path stringByAppendingPathComponent: dir]];
	}
	
	return bundleList;
}

@end


/*
 * PKBundleController main implementation part
 */

@implementation PKBundleController

static PKBundleController *	sharedInstance = nil;

+ (PKBundleController *) sharedBundleController
{
	if (sharedInstance != nil)
	{
		return sharedInstance;
	}
	else
	{
		return [[self alloc] init];
	}
}

- (id) init
{
	if (sharedInstance != nil) 
	{
		[self dealloc];
	} 
	else 
	{
		self = [super init];
		loadedBundles = [[NSMutableDictionary alloc] initWithCapacity: 5];
		sharedInstance = self;
	}
	
	return sharedInstance;
}

- (void) dealloc
{
	if (self == sharedInstance)
		return;

	[loadedBundles release];

	[super dealloc];
	sharedInstance = nil;
}

- (id) delegate
{
	return delegate;
}

- (void) setDelegate: (id)aDelegate;
{
	delegate = aDelegate;
}

- (BOOL) loadBundleWithPath: (NSString *)path
{
	NSBundle *bundle;

	if (path != nil) 
	{
		NSDebugLog(@"%@ -loadBundleWithPath: No path given!", [[self class] description]);
		return NO;
	}

	NSDebugLog(@"Loading bundle %@...", path);

	if ((bundle = [NSBundle bundleWithPath: path]) != nil) {
		
		/* Do some sanity checking to make sure we don't load a bundle twice. */
		
		if ([loadedBundles objectForKey: [[bundle infoDictionary] objectForKey: @"NSExecutable"]] != nil) {
#if 0
			NSRunAlertPanel ([[bundle bundlePath] lastPathComponent],
							 _(@"A module has already been loaded with this name!"),
							 _(@"OK"),
							 nil,
							 nil);
#else
			// FIXME: TODO - select the already-loaded module
			NSLog (@"Module \"%@\" already loaded, bailing out.", [[bundle bundlePath] lastPathComponent]);
#endif
			return NO;
		}

		NSDebugLog (@"Bundle %@ successfully loaded.", path);

		/* 
		 * Fire off the notification if we have a delegate that adopts the 
		 * PrefsApplication protocol.
		 */
		
		if (delegate != nil && [delegate respondsToSelector: @selector(moduleLoaded:)]) 
		{
			[delegate moduleLoaded: bundle];
		}		
		[loadedBundles setObject: bundle forKey: [[bundle infoDictionary] objectForKey: @"NSExecutable"]];
		
		return YES;
	}

	NSRunAlertPanel (path, _(@"Could not load bundle."), @"OK", nil, nil, path);
	
	return NO;
}

- (void) loadBundles
{
	NSMutableArray		*dirList = [[NSMutableArray alloc] initWithCapacity: 10];
	NSArray				*temp;
	NSMutableArray		*modified = [[NSMutableArray alloc] initWithCapacity: 10];
	NSEnumerator		*counter;
	id					obj;

	/* First, load and init all bundles in the app resource path. */
	
	NSDebugLog(@"Loading local bundles...");
	counter = [[self bundlesWithExtension: @"prefs" inPath: [[NSBundle mainBundle] resourcePath]] objectEnumerator];
	
	while ((obj = [counter nextObject]) != nil) 
	{
		[self loadBundleWithPath: obj];
	}

	/* Then do the same for external bundles. */
	
	NSDebugLog(@"Loading foreign bundles...");
	/* Get the library dirs and add our path to all of its entries. */
	temp = NSSearchPathForDirectoriesInDomains (NSLibraryDirectory, NSAllDomainsMask, YES);

	counter = [temp objectEnumerator];
	while ((obj = [counter nextObject]) != nil) 
	{
		[modified addObject: [obj stringByAppendingPathComponent: @"Preferences"]];
	}
	[dirList addObjectsFromArray: modified];

	/* Okay, now go through dirList loading all of the bundles in each dir. */
	
	counter = [dirList objectEnumerator];
	while ((obj = [counter nextObject]) != nil) 
	{
		NSEnumerator *enum2 = [[self bundlesWithExtension: @"prefs" inPath: obj] objectEnumerator];
		NSString *str;

		while ((str = [enum2 nextObject]) != nil) 
		{
			[self loadBundleWithPath: str];
		}
	}
}

- (NSDictionary *) loadedBundles
{
	return loadedBundles;
}

@end
