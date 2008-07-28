/*
	IKIconProvider.m

	IconKit provider class which permits to obtain icons with a set of 
	facilities supported in the background like cache mechanism and thumbnails 
	generator

	Copyright (C) 2004 Nicolas Roard <nicolas@roard.com>
	                   Quentin Mathe <qmathe@club-internet.fr> 

	Author:   Nicolas Roard <nicolas@roard.com>
	          Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2004

    This application is free software; you can redistribute it and/or 
    modify it under the terms of the 3-clause BSD license. See COPYING.
*/

#import "IKCompat.h"
#import <IconKit/IKThumbnailProvider.h>
#import "NSString+MD5Hash.h"
#import <IconKit/IKIconProvider.h>
#import <IconKit/IKApplicationIconProvider.h>
#import <IconKit/IKIconTheme.h>

#define BUNDLE_IDENTIFIER @"org.etoile-project.iconkit"

static IKIconProvider *iconProvider = nil;
static NSFileManager *fileManager = nil;
static NSWorkspace *workspace = nil;

// Private access

@interface NSWorkspace (Private)
- (NSImage*) _extIconForApp: (NSString*)appName info: (NSDictionary*)extInfo;
@end

@interface IKApplicationIconProvider (Private)
- (BOOL) _buildDirectoryStructureForCompositedIconsCache;
@end

// Private methods

@interface IKIconProvider (Private)
- (void) _loadSystemIconMappingList: (NSString *)mappingListPath;
- (NSImage *) _cachedIconForURL: (NSURL *)url;
- (void) _cacheThumbnailIcon: (NSImage *)icon forURL: (NSURL *)url;
- (NSString *) _iconsPath;
@end

@implementation IKIconProvider

/*
 * Class methods
 */

/* Not needed
+ (void) initialize
{
  if (self = [IKIconProvider class])
    {
      fileManager = [NSFileManager defaultManager];
    }
}
*/

+ (IKIconProvider *) sharedInstance
{
  if (iconProvider == nil)
    {
      iconProvider = [IKIconProvider alloc];
    }
  
  iconProvider = [iconProvider init];
  
  return iconProvider;
}

/*
 * Init methods
 */
- (id) init
{
  if (iconProvider != self)
    {
      AUTORELEASE(self);
      return RETAIN(iconProvider);
    }
  
  if ((self = [super init])  != nil)
    {
      fileManager = [NSFileManager defaultManager];
      workspace = [NSWorkspace sharedWorkspace];
      _systemIconMappingList = [[NSMutableDictionary alloc] init];
    }
  
  return self;
}

- (void) dealloc
{
  DESTROY(_systemIconMappingList);
  [super dealloc];
}

- (void) _loadSystemIconMappingList: (NSString *)mappingListPath
{
  NSAssert1(mappingListPath != nil, 
    @"%@ -loadMappingList: parameter must not be nil.", self);

  NSDictionary *extsByIdentifiers = [[NSDictionary alloc] 
    initWithContentsOfFile: mappingListPath];
  NSMutableDictionary *identifiersByExts = [NSMutableDictionary dictionary];

  AUTORELEASE(extsByIdentifiers);

  /* Generate the reverse dictionary by swapping keys and values. After that
     extensions will play key role and icon identifier value role. Take care
     of the fact each key is bound to several values put in an array. */
  NSEnumerator *e1 = [[extsByIdentifiers allKeys] objectEnumerator];
  NSString *plistFileKey = nil;

  while ((plistFileKey = [e1 nextObject]) != nil)
    {
      NSArray *plistValueArray = 
        (NSArray *)[extsByIdentifiers objectForKey: plistFileKey];
      NSEnumerator *e2 = [plistValueArray objectEnumerator];
      NSString *plistValue = nil;

      /* Flatten key structure. Each key is an array and each element of this 
         array must become a distinct key. */
      while ((plistValue = [e2 nextObject]) != nil)
        {
          [identifiersByExts setObject: plistFileKey forKey: plistValue];
        }
    }

  //NSLog(@"From original mapping %@", extsByIdentifiers);
  //NSLog(@"To inverted mapping %@", identifiersByExts);

  [_systemIconMappingList addEntriesFromDictionary: identifiersByExts];
}

/*
 * The two methods below implement an automated cache mechanism and a thumbnails
 * generator
 */

- (NSImage *) iconForURL: (NSURL *)url
{
  NSImage *icon = nil;
  //IKThumbnailProvider *thumbnailProvider = [IKThumbnailProvider sharedInstance];
  
  // FIXME: Check cache mechanism code carefully and turn icon caching on.
  //icon = [self _cachedIconForURL: url];
  // If the file has a custom icon, the icon is cached because custom icons are
  // stored in the cache
  
  /*if (icon != nil)
    return icon;*/
  
  /*if (_usesThumbnails)
    {
      NSImage *thumbnail;
      
      thumbnail = [thumbnailProvider thumbnailForURL: url size: IKThumbnailSizeNormal];
      [thumbnail setScalesWhenResized: YES];
      [thumbnail setSize: NSMakeSize(64, 64)];
      icon = thumbnail;
      [self _cacheThumbnailIcon: (NSImage *)icon forURL: url];
    }
  
  if (icon != nil)
    return icon;*/
  
  icon = [self defaultIconForURL: url];
  
  return icon;
}

- (NSImage *) iconForPath: (NSString *)path
{
  NSURL *url = [NSURL fileURLWithPath: path];
  
  return [self iconForURL: url];
}

// TODO: In future, we should use UTI database to get the proper icon 
// identifier or icon file registered by an application 
// (through make_services), as a side effect we would gain supercasting... To 
// take a bad example: when no icon has been registered for xhtml, fallback 
// occurs on any parent types (like xml, html or text) which has a registered 
// icon rather than default document icon.
/** Returns the default icon image matching url. If a custom icon has been set
	on this file or a cached icon exists, both gets ignored by this method. */
- (NSImage *) defaultIconForURL: (NSURL *)url
{
  // The method can be overriden by the desktop environment to improve the 
  // implementation or to better fit with its icons management/storage model.

  /*NSDictionary *extensionInfo = [workspace infoForExtension: extension];
  NSString *appPath = [workspace getBestAppInRole: nil forExtension: extension]; 
  NSImage *icon = [workspace _extIconForApp: appPath info: extensionInfo];*/
  
  NSString *path = [[url path] stringByStandardizingPath];
  NSString *ext = [path pathExtension];
  NSImage *icon = nil;
  BOOL isDir = NO;

  /* Try to find a third-party icon specific to this URL */
  if ([fileManager fileExistsAtPath: path isDirectory: &isDir] && isDir)
    {
      if ([workspace isFilePackageAtPath: path] 
       && [[path pathExtension] isEqual: @"app"])
        {
          IKApplicationIconProvider *appProvider = [[IKApplicationIconProvider 
            alloc] initWithBundlePath: path];
          
          //NSLog(@"Found application %@ and retrieved provider %@", 
          //  [path lastPathComponent], appProvider);
          icon = [appProvider applicationIcon];
        }
    }
  else if (isDir == NO)
    {
      NSDictionary *extInfo = [workspace infoForExtension: ext];
      NSString *appPath = [workspace getBestAppInRole: nil forExtension: ext]; 
      
      //NSLog(@"Found document %@ owned by application %@", 
      //  [path lastPathComponent], [appPath lastPathComponent]);
      icon = [workspace _extIconForApp: appPath info: extInfo];
    }

  /* If no succes, look for an appropriate system provided icon  */
  if (icon == nil)
    icon = [self systemIconForURL: url];

  return icon;
}

- (NSImage *) defaultIconForPath: (NSString *)path
{
  NSURL *url = [NSURL fileURLWithPath: path];
  
  return [self defaultIconForURL: url];
}

/** Returns the standard icon part of active icon theme for this url. If an 
	application-specific icon has been registered for this url type, it gets
	ignored by this method. To match standard icons, IconKit checks a bundled 
	mapping list which associates file types to IKIconTheme icon identifiers.
	ExtensionMapping is the name of the mapping file mentioned above. 
	Later this is going to be eliminated in favor of querying UTI database for 
	system icon identifiers. */
- (NSImage *) systemIconForURL: (NSURL *)url
{
  NSString *path = [[url path] stringByStandardizingPath];
  NSString *pathExt = [path pathExtension];
  NSBundle *bundle = [NSBundle bundleWithIdentifier: BUNDLE_IDENTIFIER];
  NSString *extMappingPath = [bundle pathForResource: @"ExtensionMapping" 
                                              ofType: @"plist"];
  NSString *identifier = nil;
  NSString *iconPath = nil;
  NSImage *icon = nil;
  BOOL isDir = NO;

  /* If no mapping from extension to icon theme identifiers is available we try
     to load usual mappings. */
  if ([_systemIconMappingList count] == 0)
    {
      //NSLog(@"%@ loads system icon mapping list at %@", self, extMappingPath);
      [self _loadSystemIconMappingList: extMappingPath];
    }

  // TODO: Support converting extension to UTI and UTI to icon identifier or 
  // icon path. Later think to add the possibility to retrieve UTI directly 
  // from a file and not only through file extension.
  if (pathExt != nil)
    identifier = [_systemIconMappingList objectForKey: pathExt];

  if (identifier == nil)
    {
      //NSLog(@"Identifier is nil in -systemIconForURL: with %@", path);
      // FIXME: Take in account more special cases.
      if ([fileManager fileExistsAtPath: path isDirectory: &isDir] && isDir)
        {
          identifier = @"folder";
        }
      else
        {
          identifier = @"document-x-generic";
        }
    }
  
  //NSLog(@"%@ found identifier %@ for item at path %@", self, identifier, path);

  iconPath = [[IKIconTheme theme] iconPathForIdentifier: identifier];
  if (iconPath == nil)
  {
    NSLog(@"WARNING: Icon identifier %@ is unknown of %@", identifier, self);
    // NOTE: May be better to display a placeholder-like icon
    iconPath = [[IKIconTheme theme] iconPathForIdentifier: @"document-x-generic"]; 
  }

  icon = [[NSImage alloc] initWithContentsOfFile: iconPath];
  NSAssert(icon!= nil, @"-systemIconForURL: must never return a nil icon");

  return AUTORELEASE(icon);
}

- (NSImage *) systemIconForPath: (NSString *)path
{
  NSURL *url = [NSURL fileURLWithPath: path];
  
  return [self systemIconForURL: url];
}

- (BOOL) usesThumbnails
{
  return _usesThumbnails;
}

- (void) setUsesThumbnails: (BOOL)flag
{
  _usesThumbnails = flag;
}

- (BOOL) ignoresCustomIcons
{
  return _ignoresCustomIcons;
}

- (void) setIgnoresCustomIcons: (BOOL)flag
{
  _ignoresCustomIcons = flag;
}

- (void) invalidCacheForURL: (NSURL *)url
{

}

- (void) recacheForURL: (NSURL *)url
{

}

- (void) invalidCacheForPath: (NSString *)path
{

}

- (void) recacheForPath: (NSString *)path
{

}

- (NSString *) _iconsPath
{
  NSArray *locations = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
  // NOTE: We cannot use NSLocalDomainMask without authorization, then we stick
  // to User domain now.
  NSString *path;
  
  if ([locations count] == 0)
    {
      // Raise exception
    }
  
  path = [locations objectAtIndex: 0];
  path = [path stringByAppendingPathComponent: @"Caches"];
  path = [path stringByAppendingPathComponent: @"IconKit"];
  
  return [path stringByAppendingPathComponent: @"Icons"];
}

- (NSImage *) _cachedIconForURL: (NSURL *)url
{
  NSString *path;
  NSString *subpath;
  NSString *pathComponent;
  BOOL isDir;

  path = [self _iconsPath];

  // Check for a custom icon
  subpath = [path stringByAppendingPathComponent: @"Custom"];
  pathComponent = [[[url absoluteString] md5Hash] stringByAppendingPathExtension: @"tiff"];
  subpath = [subpath stringByAppendingPathComponent: pathComponent];
  if ([fileManager fileExistsAtPath: path isDirectory: &isDir] && !isDir)
    return [[NSImage alloc] initWithContentsOfFile: subpath];
  
  // Check for a thumbnail icon
  subpath = [path stringByAppendingPathComponent: @"Thumbnails"];
  pathComponent = [[[url absoluteString] md5Hash] stringByAppendingPathExtension: @"tiff"];
  subpath = [subpath stringByAppendingPathComponent: pathComponent];
  if ([fileManager fileExistsAtPath: path isDirectory: &isDir] && !isDir)
    return [[NSImage alloc] initWithContentsOfFile: subpath];
    
  return nil;
}

- (void) _cacheThumbnailIcon: (NSImage *)icon forURL: (NSURL *)url
{
  NSString *path;
  NSString *pathComponent;
  NSData *data;
  // FIXME: Checks the file exists
  // BOOL isDir;

  path = [self _iconsPath];
  
  path = [path stringByAppendingPathComponent: @"Thumbnails"];
  pathComponent = [[[url absoluteString] md5Hash] stringByAppendingPathExtension: @"tiff"];
  path = [path stringByAppendingPathComponent: pathComponent];
  data = [icon TIFFRepresentation];
  [data writeToFile: path atomically: YES];
}

@end
