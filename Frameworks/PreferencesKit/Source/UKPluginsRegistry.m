/*
	UKPluginsRegistry.m
 
	Plugins manager class used to register new plugins and obtain already
 registered plugins
 
	Copyright (C) 2004 Uli Kusterer
 
	Author:  Uli Kusterer
            Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2004
 
	This library is free software; you can redistribute it and/or
	modify it under the terms of the GNU Lesser General Public
	License as published by the Free Software Foundation; either
	version 2.1 of the License, or (at your option) any later version.
 
	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
	Lesser General Public License for more details.
 
	You should have received a copy of the GNU Lesser General Public
	License along with this library; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import <AppKit/AppKit.h>
#import "UKPluginsRegistry.h"

#ifdef HAVE_UKTEST
#import <UnitKit/UnitKit.h>
#endif

#ifdef GNUSTEP
#define EXECUTABLE_ENTRY @"NSExecutable"
#define NAME_ENTRY @"ApplicationName"
#define ICON_FILE_ENTRY @"NSIcon"
#define BUNDLE_INDENTIFIER_ENTRY @"CFBundleIdentifier"
#else
#define EXECUTABLE_ENTRY @"CFBundleExecutable"
#define NAME_ENTRY @"CFBundleName"
#define ICON_FILE_ENTRY @"CFBundleIconFile"
#define BUNDLE_INDENTIFIER_ENTRY @"CFBundleIdentifier"
#endif

static NSFileManager *fm = nil;


@implementation UKPluginsRegistry

+ (id) sharedRegistry
{
	static UKPluginsRegistry *sharedPluginRegistry = nil;
	
	if (sharedPluginRegistry == NO)
		sharedPluginRegistry = [[UKPluginsRegistry alloc] init];
	
	return sharedPluginRegistry;
}

/* First test to run */
#ifdef HAVE_UKTEST
- (void) test_Init
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);
    
    UKNotNil(paths);
    UKTrue([paths count] >= 1);
}
#endif

- (id) init
{
	self = [super init];
	if (self == nil)
		return nil;
	
	plugins = [[NSMutableArray alloc] init];
	pluginPaths = [[NSMutableDictionary alloc] init];
	fm = [NSFileManager defaultManager];
    instantiate = YES;
    
	return self;
}


- (void) dealloc
{
	[plugins release];
	[pluginPaths release];
	
	[super dealloc];
}

#ifdef HAVE_UKTEST
- (void) testLoadPluginOfType
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSDictionary *info = [bundle infoDictionary];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);
    
    UKNotNil(bundle);
    UKNotNil(info);

    NSString *supportDir = 
        [[paths objectAtIndex: 0] stringByAppendingPathComponent: @"Application Support"];
    BOOL isDir;
    
    UKTrue([fm fileExistsAtPath: supportDir isDirectory:&isDir]);
    UKTrue(isDir);
}
#endif

- (void) loadPluginsOfType: (NSString *)ext
{
	NSBundle *bundle = [NSBundle mainBundle];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);
    NSEnumerator *e = [paths objectEnumerator];
	NSString *path = nil;
	NSString *appName = [[bundle infoDictionary] objectForKey: EXECUTABLE_ENTRY];
	NSString *pluginsDir = [[@"Application Support" stringByAppendingPathComponent: appName] 
        stringByAppendingPathComponent: @"PlugIns"];
	
	while ((path = [e nextObject]) != nil)
	{
		[self loadPluginsFromPath: [path stringByAppendingPathComponent: pluginsDir] ofType: ext];
	}
	[self loadPluginsFromPath: [bundle builtInPlugInsPath] ofType: ext];
}

- (void) loadPluginsFromPath: (NSString *)folder ofType: (NSString *)ext
{
	NSDirectoryEnumerator *e = [fm enumeratorAtPath: folder];
	NSString *fileName = nil;
	
	while ((fileName = [e nextObject]) != nil )
	{
		[e skipDescendents];	/* Ignore subfolders and don't search in packages. */
		
		/* Skip invisible files: */
		if ([fileName characterAtIndex: 0] == '.')
			continue;
		
		/* Only process ones that have the right suffix: */
		if ([[fileName pathExtension] isEqualToString: ext] == NO)
			continue;
		
		NS_DURING
			/* Get path, bundle and display name: */
			NSString *path = [folder stringByAppendingPathComponent: fileName];
			
			[self loadPluginForPath: path];
            
		NS_HANDLER
            
			NSLog(@"Error while listing PrefPane: %@", localException);
            
		NS_ENDHANDLER
	}
}
#ifdef HAVE_UKTEST
- (void) testLoadPluginForPath
{
    NSArray *paths;
    NSString *path;
#ifdef GNUstep
    paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);
    path = [[paths objectAtIndex: 0] stringByAppendingPathComponent: @"PreferencePanes/PrefPaneExample.prefPane"];
#else
    paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSSystemDomainMask, YES);
    path = [[paths objectAtIndex: 0] stringByAppendingPathComponent: @"PreferencePanes/Appearance.prefPane"];
#endif
    NSBundle *bundle = [NSBundle bundleWithPath: path];
    NSDictionary *info = [bundle infoDictionary];
    int lastCount = [plugins count];
    BOOL isDir;
    
    UKTrue([fm fileExistsAtPath: path isDirectory: &isDir]);
    UKNotNil(bundle);
    UKNotNil(info);
    UKTrue([[info allKeys] containsObject: NAME_ENTRY]);
    
    [self loadPluginForPath: path];
    
    UKTrue(instantiate);
    UKIntsEqual([plugins count], lastCount + 1);
    
    UKTrue([[pluginPaths allKeys] containsObject: path]);
        
    info = [pluginPaths objectForKey: path];
    UKNotNil(info);
    UKTrue([[info allKeys] containsObject: @"bundle"]);
    UKTrue([[info allKeys] containsObject: @"image"]);
    UKTrue([[info allKeys] containsObject: @"name"]);
    UKTrue([[info allKeys] containsObject: @"path"]);
    UKTrue([[info allKeys] containsObject: @"class"]);
}
#endif

- (NSMutableDictionary *) loadPluginForPath: (NSString *)path
{
	NSMutableDictionary *info = [pluginPaths objectForKey: path];
	
	if(info == nil)
	{
		NSBundle *bundle = [NSBundle bundleWithPath: path];
		NSString *prefPaneName = [[bundle infoDictionary] objectForKey: NAME_ENTRY];
		if (prefPaneName == nil)
			prefPaneName = @"Unknown";
		
		/* Get icon, falling back on file icon when needed, or in worst case using our app icon: */
		NSString *iconFileName = [[bundle infoDictionary] objectForKey: @"NSPrefPaneIconFile"];
        NSString *imageFileName = nil;
        NSImage *image;
		
        if(iconFileName == nil)
			iconFileName = [[bundle infoDictionary] objectForKey: ICON_FILE_ENTRY];

		if (iconFileName != nil) 
            imageFileName = [bundle pathForResource: iconFileName ofType: @""];
            
        if (imageFileName == nil)
        {
            image = [NSImage imageNamed: @"NSApplicationIcon"];
        }
        else
        {
            image = [[[NSImage alloc] initWithContentsOfFile: imageFileName] autorelease];
        }
		
		/* Add a new entry for this pane to our list: */
		info = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
            bundle, @"bundle", image, @"image", prefPaneName, @"name", path, @"path", 
            [NSValue valueWithPointer: [bundle principalClass]], @"class", nil];

        if (instantiate)
        {
            id obj = [[[[bundle principalClass] alloc] init] autorelease];
            
            [info setObject: obj forKey: @"instance"];
        }
		[plugins addObject: info];
		[pluginPaths setObject: info forKey: path];
	}
	
	return info;
}

#ifdef HAVE_UKTEST
- (void) testLoadedPlugins
{
    UKNotNil([self loadedPlugins]);
}
#endif

- (NSArray *) loadedPlugins
{
	return plugins;
}


- (BOOL)  instantiate
{
    return instantiate;
}


- (void) setInstantiate: (BOOL)n
{
    instantiate = n;
}

@end
