/*
	IKIconTheme.m

	IKIconTheme class provides icon theme support (finding, loading icon 
	theme bundles and switching between them)

	Copyright (C) 2007 Quentin Mathe <qmathe@club-internet.fr>

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  February 2007

	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	1. Redistributions of source code must retain the above copyright notice,
	   this list of conditions and the following disclaimer.
	2. Redistributions in binary form must reproduce the above copyright notice,
	   this list of conditions and the following disclaimer in the documentation
	   and/or other materials provided with the distribution.
	3. The name of the author may not be used to endorse or promote products
	   derived from this software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED
	WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
	MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
	EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
	EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
	OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
	IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
	OF SUCH DAMAGE.
*/

#import "IKCompat.h"
#import <IconKit/IKIconTheme.h>
#ifdef HAVE_UKTEST
#import <UnitKit/UnitKit.h>
#endif


/*
 * Private variables and constants
 */

#define ThemePathComponent @"Themes"
#define IconThemePathComponent @"Themes/Icon"
#define IconThemeExt @"icontheme"

/* All the themes found by IKIconTheme on load and keyed by their bundle
   name */
static NSMutableDictionary *themes = nil;
static IKIconTheme *activeTheme = nil;

/*
 * Private methods
 */

@interface IKIconTheme (IconKitPrivate)
+ (NSDictionary *) findAllThemeBundles;
+ (NSDictionary *) themeBundlesInDirectory: (NSString *)themeFolder;
+ (IKIconTheme *) loadThemeBundleAtPath: (NSString *)themePath;

- (NSString *) path;

- (void) loadIdentifierMappingList;

@end

/*
 * Main implementation
 */

@implementation IKIconTheme

+ (void) initialize
{
	if (self == [IKIconTheme class])
	{
		themes = [[NSMutableDictionary alloc] init];
	}
}

#ifdef HAVE_UKTEST

+ (void) testFindAllThemeBundles
{
	NSDictionary *themeBundlePaths = [IKIconTheme findAllThemeBundles];

	UKNotNil(themeBundlePaths);
	// NOTE: The following test will fail if no theme bundle has been installed 
	// in standard locations.
	UKTrue([themeBundlePaths count] >= 1);
}

#endif

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

#ifdef HAVE_UKTEST

+ (void) testThemeBundlesInDirectory
{
	NSString *iconKitDir = [[NSFileManager defaultManager] currentDirectoryPath];
	NSDictionary *themeBundlePaths = 
		[IKIconTheme themeBundlesInDirectory: iconKitDir];
	NSBundle *themeBundle = nil;

	NSLog(@"Found %@ as IconKit directory", iconKitDir);

	UKNotNil(themeBundlePaths);
	UKTrue([themeBundlePaths count] >= 1);

	themeBundle = [themeBundlePaths objectForKey: @"test"];
	UKNotNil(themeBundle);
}

#endif

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

#ifdef HAVE_UKTEST

+ (void) testLoadThemeBundleAtPath
{
	NSString *iconKitDir = [[NSFileManager defaultManager] currentDirectoryPath];
	NSString *themeBundlePath = [[IKIconTheme 
		themeBundlesInDirectory: iconKitDir] objectForKey: @"test"];
	IKIconTheme *theme = nil;

	theme = [IKIconTheme loadThemeBundleAtPath: themeBundlePath];

	UKNotNil(theme);

	UKNotNil(themes);
	UKTrue([themes count] >= 1);

	theme = [themes objectForKey: @"test"];
	UKNotNil(theme);
	UKStringsEqual([theme path], themeBundlePath);
}

#endif

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

- (id) initForTest
{
	NSString *path = [[NSFileManager defaultManager] currentDirectoryPath];

	//NSLog(@"%@ initForTest", self);

	path = [[path stringByAppendingPathComponent: @"test.icontheme"]
		stringByStandardizingPath];

	return [self initWithPath: path];
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

#ifdef HAVE_UKTEST

- (void) testLoadIdentifierMappingList
{
	[self loadIdentifierMappingList];

	UKNotNil(_specIdentifiers);
	UKStringsEqual([_specIdentifiers objectForKey: @"home"], @"Folder-Home");
	NSLog(@"Identifier mapping list loaded: %@", _specIdentifiers);
}

#endif

- (void) loadIdentifierMappingList
{
	NSString *mappingListPath = [_themeBundle 
		pathForResource: @"IdentifierMapping" ofType: @"plist"];

	NSAssert1(mappingListPath != nil, 
		@"Found no IdentifierMapping.plist file in Resources folder of %@", self);

	ASSIGN(_specIdentifiers, [[NSDictionary alloc] 
		initWithContentsOfFile: mappingListPath]);
}

#ifdef HAVE_UKTEST

- (void) testIconPathForIdentifier
{
	NSString *path = [self iconPathForIdentifier: @"folder"];
	NSArray *components = [path pathComponents];
	int lastIndex = [components count] - 1;

	UKNotNil(path);
	UKStringsEqual([components objectAtIndex: lastIndex], @"folder.tif");
	UKStringsEqual([components objectAtIndex: --lastIndex], @"Resources");
	UKStringsEqual([components objectAtIndex: --lastIndex], @"test.icontheme");

	path = [self iconPathForIdentifier: @"home"];
	components = [path pathComponents];
	lastIndex = [components count] - 1;

	UKNotNil(path);
	UKStringsEqual([components objectAtIndex: lastIndex], @"Folder-Home.tif");
}

#endif

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

@end
