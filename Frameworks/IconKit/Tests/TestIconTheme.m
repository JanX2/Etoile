/*
	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  August 2009
	License:  Modified BSD (see COPYING)
 */

#import "IKCompat.h"
#import "IKIconTheme.h"
#import <UnitKit/UnitKit.h>

@interface IKIconTheme (IconKitPrivate)
+ (NSDictionary *) loadedThemes;
+ (NSDictionary *) findAllThemeBundles;
+ (NSDictionary *) themeBundlesInDirectory: (NSString *)themeFolder;
+ (IKIconTheme *) loadThemeBundleAtPath: (NSString *)themePath;
- (NSString *) path;
- (void) loadIdentifierMappingList;
@end

@interface IKIconTheme (Test) <UKTest>
@end


@implementation IKIconTheme (Test)

+ (void) testFindAllThemeBundles
{
	NSDictionary *themeBundlePaths = [IKIconTheme findAllThemeBundles];

	UKNotNil(themeBundlePaths);
	// NOTE: Will fail if no theme bundle has been installed
	UKTrue([themeBundlePaths count] >= 1);
}

+ (void) testThemeBundlesInDirectory
{
	NSString *iconKitDir = [[NSFileManager defaultManager] currentDirectoryPath];
	NSDictionary *themeBundlePaths = [IKIconTheme themeBundlesInDirectory: iconKitDir];
	NSBundle *themeBundle = nil;

	NSLog(@"Found %@ as IconKit directory", iconKitDir);

	UKNotNil(themeBundlePaths);
	UKTrue([themeBundlePaths count] >= 1);

	themeBundle = [themeBundlePaths objectForKey: @"test"];
	UKNotNil(themeBundle);
}

+ (void) testLoadThemeBundleAtPath
{
	NSString *iconKitDir = [[NSFileManager defaultManager] currentDirectoryPath];
	NSString *themeBundlePath = [[IKIconTheme 
		themeBundlesInDirectory: iconKitDir] objectForKey: @"test"];
	IKIconTheme *theme = [IKIconTheme loadThemeBundleAtPath: themeBundlePath];

	UKNotNil(theme);

	UKNotNil([self loadedThemes]);
	UKTrue([[self loadedThemes] count] >= 1);

	theme = [[self loadedThemes] objectForKey: @"test"];
	UKNotNil(theme);
	UKStringsEqual([theme path], themeBundlePath);
}

- (id) initForTest
{
	NSString *path = [[NSFileManager defaultManager] currentDirectoryPath];

	//NSLog(@"%@ initForTest", self);

	path = [[path stringByAppendingPathComponent: @"test.icontheme"]
		stringByStandardizingPath];

	return [self initWithPath: path];
}

- (void) testLoadIdentifierMappingList
{
	[self loadIdentifierMappingList];

	UKNotNil(_specIdentifiers);
	UKStringsEqual([_specIdentifiers objectForKey: @"home"], @"Folder-Home");
	NSLog(@"Identifier mapping list loaded: %@", _specIdentifiers);
}

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

@end
