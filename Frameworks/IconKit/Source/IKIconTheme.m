/*
	IKIconTheme.m

	IKIconTheme class provides icon theme support (finding, loading icon 
	theme bundles and switching between them)

	Copyright (C) 2007 Quentin Mathe <qmathe@club-internet.fr>

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  February 2007

    This application is free software; you can redistribute it and/or 
    modify it under the terms of the 3-clause BSD license. See COPYING.
*/

#import "IKCompat.h"
#import "IKIconTheme.h"

#define ThemePathComponent @"Themes"
#define IconThemePathComponent @"Themes/Icon"
#define IconThemeExt @"icontheme"

/* All the themes found by IKIconTheme on load and keyed by their bundle
   name */
static NSMutableDictionary *themes = nil;
static IKIconTheme *activeTheme = nil;

@interface IKIconTheme (IconKitPrivate)
+ (NSDictionary *) findAllThemeBundles;
+ (NSDictionary *) themeBundlesInDirectory: (NSString *)themeFolder;
+ (IKIconTheme *) loadThemeBundleAtPath: (NSString *)themePath;
- (NSString *) path;
- (void) loadIdentifierMappingList;
@end


@implementation IKIconTheme

+ (void) initialize
{
	if (self == [IKIconTheme class])
	{
		themes = [[NSMutableDictionary alloc] init];
	}
}

+ (NSDictionary *) findAllThemeBundles
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
		NSAllDomainsMask, YES);
	NSEnumerator *e = [paths objectEnumerator];
	NSString *parentPath = nil;
	NSMutableDictionary *allThemeBundlePaths = [NSMutableDictionary dictionary];

	NSString *themeFolder = nil;
	NSDictionary *themeBundlePaths = nil;
	while ((parentPath = [e nextObject]) != nil)
	{
		themeFolder = [parentPath 
			stringByAppendingPathComponent: ThemePathComponent];
		themeBundlePaths = [IKIconTheme 
			themeBundlesInDirectory: themeFolder];

		[allThemeBundlePaths addEntriesFromDictionary: themeBundlePaths];

		/* Also tries to find themes directly in Icon Themes folder in addition
		   to Themes folder. */
		themeFolder = [parentPath 
			stringByAppendingPathComponent: IconThemePathComponent];
		themeBundlePaths =  [IKIconTheme themeBundlesInDirectory: themeFolder];

		[allThemeBundlePaths addEntriesFromDictionary: themeBundlePaths];
	}
	/* We look for framework resource */
	themeFolder = [[NSBundle bundleForClass: [self class]] resourcePath];
	themeBundlePaths =  [IKIconTheme themeBundlesInDirectory: themeFolder];
	[allThemeBundlePaths addEntriesFromDictionary: themeBundlePaths];

	return allThemeBundlePaths;
}

+ (NSDictionary *) themeBundlesInDirectory: (NSString *)themeFolder
{
	NSParameterAssert(themeFolder != nil);

	NSDirectoryEnumerator *e = 
		[[NSFileManager defaultManager] enumeratorAtPath: themeFolder];
	NSString *themeBundleName = nil;
	NSMutableDictionary *themeBundlePaths = [NSMutableDictionary dictionary];

	NSAssert1(e != nil, @"No directory found at path %@", themeFolder);

	NSDebugLLog(@"IconKit", @"Find themes in directory %@", themeFolder);

	while ((themeBundleName = [e nextObject]) != nil )
	{
		/* Ignore subfolders and don't search in packages */
		if ([[[e fileAttributes] fileType] isEqual: NSFileTypeDirectory])
			[e skipDescendents]; 

		/* Skip invisible files */
		if ([themeBundleName characterAtIndex: 0] == '.')
			continue;

		/* Only process ones that have the right suffix */
		if ([[themeBundleName pathExtension] isEqual: IconThemeExt] == NO)
			continue;
		
		NSDebugLLog(@"IconKit", @"Found theme %@ in directory %@", 
			themeBundleName, themeFolder);
		
		NS_DURING
			/* Get path, bundle and display name */
			NSString *themePath = [themeFolder 
				stringByAppendingPathComponent: themeBundleName];

			[themeBundlePaths setObject: themePath 
				forKey: [themeBundleName stringByDeletingPathExtension]];

		NS_HANDLER

			NSLog(@"Unable to list theme folder %@", localException);

		NS_ENDHANDLER
	}

	return themeBundlePaths;
}

+ (IKIconTheme *) loadThemeBundleAtPath: (NSString *)themePath
{
	NSParameterAssert(themePath != nil);

	NSBundle *themeBundle = [NSBundle bundleWithPath: themePath];

	if (themeBundle == nil)
	{
		NSLog(@"Found no valid bundle at path %@", themePath);
		return nil;
	}

	IKIconTheme *loadedTheme = AUTORELEASE([[IKIconTheme alloc] init]);
	NSString *identifier = [[themeBundle infoDictionary] 
		objectForKey: @"ThemeName"];

	if (identifier == nil)
		identifier = [[themeBundle infoDictionary] objectForKey: @"BundleName"];

	if (identifier == nil)
		identifier = [[themeBundle infoDictionary] objectForKey: @"CFBundleName"];

	if (identifier == nil)
	{
		identifier = [[themePath lastPathComponent] 
			stringByDeletingPathExtension];

		NSLog(@"Found no valid icon theme name in bundle infoDictionary, we \
will use theme bundle name %@", identifier);
	}

	ASSIGN(loadedTheme->_themeBundle, themeBundle);
	ASSIGN(loadedTheme->_themeName, identifier);
	[loadedTheme loadIdentifierMappingList];

	[themes setObject: loadedTheme forKey: identifier];

	return loadedTheme;
}

+ (IKIconTheme *) theme
{
	/* If no theme has been already set, we try to load and active default 
	   GNUstep theme. */
	if (activeTheme == nil)
	{
		IKIconTheme *defaultTheme = 
			AUTORELEASE([[IKIconTheme alloc] initWithTheme: @"GNUstep"]);

		[IKIconTheme setTheme: defaultTheme];
	}

	return activeTheme;
}

+ (void) setTheme: (IKIconTheme *)theme
{
	ASSIGN(activeTheme, theme);
	[activeTheme activate];
}

- (NSString *) path
{
	return [_themeBundle bundlePath];
}

- (id) initWithPath: (NSString *)path
{
	NSParameterAssert(path != nil);

	self = RETAIN([IKIconTheme loadThemeBundleAtPath: path]);

	return self;
}

- (id) initWithTheme: (NSString *)identifier
{
	NSParameterAssert(identifier != nil);

	IKIconTheme *loadedTheme = [themes objectForKey: identifier];

	if (loadedTheme != nil)
	{
		RELEASE(self);
		self = RETAIN(loadedTheme);
	}
	else
	{
		NSDictionary *themeBundlePaths = [IKIconTheme findAllThemeBundles];
		NSString *path = [themeBundlePaths objectForKey: identifier];

		if (path == nil)
		{
			NSLog(@"Found no theme bundle with identifier %@", identifier);
			return nil;
		}

		self = RETAIN([IKIconTheme loadThemeBundleAtPath: path]);

		// NOTE: We already make this check in +loadThemeBundleAtPath:
		if (_themeBundle == nil)
		{
			NSLog(@"Failed to load theme located at %@", path);
			return nil;
		}
	}

	return self;
}

- (void) dealloc
{
	DESTROY(_specIdentifiers);
	DESTROY(_themeBundle);

	[super dealloc];
}

- (NSString *) description
{
	return [super description];

}

- (void) loadIdentifierMappingList
{
	NSString *mappingListPath = [_themeBundle 
		pathForResource: @"IdentifierMapping" ofType: @"plist"];

	NSAssert1(mappingListPath != nil, 
		@"Found no IdentifierMapping.plist file in Resources folder of %@", self);

	ASSIGN(_specIdentifiers, [[NSDictionary alloc] 
		initWithContentsOfFile: mappingListPath]);
}

- (NSString *) iconPathForIdentifier: (NSString *)iconIdentifier
{
	NSString *realIdentifier = [_specIdentifiers objectForKey: iconIdentifier];
	NSString *imageType = @"tif";

	NSDebugLLog(@"IconKit", @"For identifier %@, mapping list returns %@", 
		iconIdentifier, realIdentifier);

	if (realIdentifier == nil)
		realIdentifier = iconIdentifier;

	if ([realIdentifier pathExtension] != nil)
	{
		imageType = [realIdentifier pathExtension];
		realIdentifier = [realIdentifier stringByDeletingPathExtension];
//		imageType = nil;
	}

	// NOTE: We may use -pathForImageResource:
	NSDebugLLog(@"IconKit", @"path %@.%@", realIdentifier, imageType);
	return [_themeBundle pathForResource: realIdentifier ofType: imageType];
}

- (NSURL*) iconURLForIdentifier: (NSString *)iconIdentifier
{
	NSURL *iconURL = 
		[NSURL fileURLWithPath: [self iconPathForIdentifier: iconIdentifier]];

	return iconURL;
}

- (void) activate
{
	// TODO
}

- (void) deactivate
{
	// TODO
}

/* For TestIconTheme */

+ (NSDictionary *) loadedThemes
{
	return themes;
}

@end
