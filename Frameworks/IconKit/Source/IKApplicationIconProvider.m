/*
	IKApplicationIconProvider.m

	IKIconProvider subclass which offers when needed special facilities like on 
	the fly composited applications, documents and plugins icons (with its own
	cache mechanism)

	Copyright (C) 2004 Nicolas Roard <nicolas@roard.com>
	                   Quentin Mathe <qmathe@club-internet.fr>

	Author:   Nicolas Roard <nicolas@roard.com>
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

#import <IconKit/IKCompositor.h>
#import <IconKit/IKCompositorOperation.h>
#import "NSString+MD5Hash.h"
#import "NSFileManager+IconKit.h"
#import <IconKit/IKApplicationIconProvider.h>

#ifdef HAVE_UKTEST
#import <UnitKit/UnitKit.h>

/* For tests object initialization with UnitKit */
#define TEST_APPLICATION_PACKAGE @"~/GNUstep/Applications/UnitTests"
#endif

#define DOCUMENT_PATH_COMPONENT @"Document"
#define PLUGIN_PATH_COMPONENT @"Plugin"

typedef enum _IKIconVariant
{
  IKIconVariantDocument,
  IKIconVariantPlugin
} IKIconVariant;

static NSWorkspace *workspace = nil;
static NSFileManager *fileManager = nil;

// Private access

@interface NSWorkspace (Private)
- (NSImage*) _extIconForApp: (NSString*)appName info: (NSDictionary*)extInfo;
@end

// Private methods

@interface IKApplicationIconProvider (Private)
- (NSImage *) _blankDocumentIcon;
- (NSImage *) _blankPluginIcon;
- (BOOL) _buildDirectoryStructureForCompositedIconsCache;
- (NSImage *) _cachedIconForVariant: (IKIconVariant)variant;
- (void) _cacheIcon: (NSImage *)icon forVariant: (IKIconVariant)variant;
- (NSString *) _compositedIconsPath;
- (NSImage *) _compositeIconForVariant: (IKIconVariant)variant;
- (void) _obtainBundlePathIfNeeded;
@end

@implementation IKApplicationIconProvider

/*
 * Class methods
 */

+ (void) initialize
{
	if (self == [IKApplicationIconProvider class])
    {
      workspace = [NSWorkspace sharedWorkspace];
      fileManager = [NSFileManager defaultManager];
    }
}

/*
 * Init methods
 */

#ifdef HAVE_UKTEST
- (id) initForTest
{
  return [self initWithBundlePath: TEST_APPLICATION_PACKAGE];
}
 
- (void) testInit
{
  UKNotNil(workspace);
  UKNotNil(fileManager);
}
#endif

- (id) initWithBundlePath: (NSString *)path
{
  if ((self = [super init]) != nil)
    {
      BOOL dir;
      
      if (path == nil)
        {  
          [NSException raise: NSInvalidArgumentException format: 
            @"IKApplicationIconProvider object cannot be instantiated with nil \
            path.", nil];
        }
      
      if ([fileManager fileExistsAtPath: path isDirectory: &dir] == NO || dir == NO)
        {
          [NSException raise: NSInvalidArgumentException format: 
            @"IKApplicationIconProvider object needs a valid path to be \
            instantiated.", nil];
        }
      
      ASSIGN(_path, path);
      
      return self;
    }
    
  return nil;
}

- (id) initWithBundleIdentifier: (NSString *)identifier
{
  if ((self = [super init]) != nil)
    {
      if (identifier == nil)
        {
          [NSException raise: NSInvalidArgumentException format: 
            @"IKApplicationIconProvider object cannot be instantiated with nil \
            identifier.", nil];
        }
      
      // FIXME: Raise exception if identifier is unknown.
      
      ASSIGN(_identifier, identifier);
      // NOTE: the path of the application package for this identifier will be
      // retrieved lazily with -_obtainBundlePathIfNeeded
      
      return self;
    }
    
  return nil;
}

// ---

#ifdef HAVE_UKTEST
- (void) testApplicationIcon
{
  UKTrue([workspace isFilePackageAtPath: _path]);
  UKNotNil([self applicationIcon]);
}
#endif

- (NSImage *) applicationIcon
{
  [self _obtainBundlePathIfNeeded];
  
  if (_path != nil)   
    return [workspace appIconForApp: _path];
  
  return nil;
}

/*
 * GNUstep compatible implementation, but should be overriden in favor of an 
 * improved implementation in Etoile with ExtendedWorkspaceKit
 */
 
#ifdef HAVE_UKTEST
- (void) test_documentIconForExtension
{
  UKNotNil(_path);
  UKNotNil([workspace infoForExtension: @"tiff"]);
}
#endif

- (NSImage *) documentIconForExtension: (NSString *)extension
{
  // We do not use -_iconForExtension: or -iconForFileType because we don't want
  // the workspace behavior, we want a custom behavior
  
  NSDictionary *extensionInfo;
  NSImage *icon = nil;
  
  [self _obtainBundlePathIfNeeded];
  
  if (_path == nil)
    {
      NSLog(@"No path available for the application package.");
      return nil;
      // Pathological case, should never happen
    }
  
  // We try to retrieve the special icon associated with the extension for the 
  // application matched by _path
  extensionInfo = [workspace infoForExtension: extension];
  if (extensionInfo != nil)
    {
      NSLog(@"For extension %@, NSWorkspace returns info: %@", extension, extensionInfo);
      icon = [workspace _extIconForApp: _path info: extensionInfo];
    }
  
  // We are ignoring voluntarly the custom icon which can be set by the user for
  // the files with a specific extension. See NSWorkspace 
  // -setBestIcon:forExtension: -getBestIconForExtension: methods
  // We are also ignoring woluntarly the default application (with its icons set)
  // associated with the extension
  
  if (icon != nil)
    return icon;
  
  // If we found no icon, check the cache for composited icons
  icon = [self _cachedIconForVariant: IKIconVariantDocument];
  if (icon != nil)
    return icon;
  
  // If we still found no icon, composite and cache the icon
  icon = [self _compositeIconForVariant: IKIconVariantDocument];
  if (icon != nil)
    [self _cacheIcon: icon forVariant: IKIconVariantDocument];
  
  return icon;
}

/* We should add a method in Etoile within the ExtendedWorkspaceKit like
- (NSImage *) documentIconForUTI: (EWUTI *)uti
{

}
*/

- (NSImage *) pluginIcon
{
  NSImage *icon;
  
  // Check the cache for composited icons
  icon = [self _cachedIconForVariant: IKIconVariantPlugin];
  if (icon != nil)
    return icon;
  
  icon = [self _compositeIconForVariant: IKIconVariantPlugin];
  if (icon != nil)
    [self _cacheIcon: icon forVariant: IKIconVariantPlugin];
  
  return icon;
}

- (void) invalidateCache
{
  NSString *path;
  NSString *subpath;
  NSString *pathComponent = [_path md5Hash];
  BOOL result;
  
  pathComponent = [pathComponent stringByAppendingPathExtension: @"tiff"];
  
  path = [self _compositedIconsPath];  
  
  // We remove the composited icon in the Document directory of the cache
  subpath = [path stringByAppendingPathComponent: @"Document"];
  subpath = [subpath stringByAppendingPathComponent: pathComponent];
  
  [fileManager removeFileAtPath: subpath handler: nil];
  if (result == NO)
    {
      NSLog(@"Impossible to invalidate document composited icon cache for the \
        application %@", _path);
    }
  
  // We remove the composited icon in the Plugin directory of the cache  
  subpath = [path stringByAppendingPathComponent: @"Plugin"];
  subpath = [subpath stringByAppendingPathComponent: pathComponent];
  
  [fileManager removeFileAtPath: subpath handler: nil];
  if (result == NO)
    {
      NSLog(@"Impossible to invalidate plugin composited icon cache for the \
        application %@", _path);
    }
}

- (void) invalidateCacheAll
{
  NSString *path = [self _compositedIconsPath];
  BOOL result = NO;
  
  result = [fileManager removeFileAtPath: path handler: nil];
  
  if (result == NO)
    {
      NSLog(@"Impossible to invalidate the composited icons cache");
    }
}

- (void) recache
{
  NSImage *icon;
  
  [self invalidateCache];
  
  icon = [self _compositeIconForVariant: IKIconVariantDocument];
  if (icon != nil)
    [self _cacheIcon: icon forVariant: IKIconVariantDocument];
  
  icon = [self _compositeIconForVariant: IKIconVariantPlugin];
  if (icon != nil)
    [self _cacheIcon: icon forVariant: IKIconVariantPlugin];
}

#ifdef HAVE_UKTEST
- (void) test_compositeIconForVariant
{
  UKNotNil([self _compositeIconForVariant: IKIconVariantDocument]);
}
#endif

- (NSImage *) _compositeIconForVariant: (IKIconVariant)variant
{
  IKCompositor *compositor;
  
  switch (variant)
    {
      case IKIconVariantDocument:
        compositor = 
          [[IKCompositor alloc] initWithImage: [self _blankDocumentIcon]];
        break;
      
      case IKIconVariantPlugin:
        compositor = 
          [[IKCompositor alloc] initWithImage: [self _blankPluginIcon]];
        break;
    
      default:
        // Pathological case
        return nil;
    }
  
  [compositor compositeImage: [self applicationIcon] 
                withPosition: IKCompositedImagePositionBottomRight];
  return [compositor render]; 
}

#ifdef HAVE_UKTEST
- (void) test_compositedIconsPath
{
  UKNotNil([self _compositedIconsPath]);
  UKNotNil([NSBundle bundleWithPath: _path]);
}
#endif

- (NSString *) _compositedIconsPath
{
  NSArray *locations = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, 
    NSUserDomainMask, YES); 
  // NOTE: We cannot use NSLocalDomainMask without authorization, then we stick
  // to User domain now.
  NSString *path;
  
  if ([locations count] == 0)
    {
      NSLog(@"No location found to put composited icons path");
      // Raise exception
    }
  
  path = [locations objectAtIndex: 0];
  path = [path stringByAppendingPathComponent: @"Caches"];
  path = [path stringByAppendingPathComponent: @"IconKit"];
  
  return [path stringByAppendingPathComponent: @"Composited icons"];
}

#ifdef HAVE_UKTEST
- (void) test_cachedIconForVariant
{
  NSString *path = [self _compositedIconsPath];
  NSFileManager *fm = [NSFileManager defaultManager];
  BOOL dir;
  NSBundle *appBundle;
  
  UKNotNil(path);
  UKTrue([fm fileExistsAtPath: path isDirectory: &dir]);
  UKTrue(dir);
  
  appBundle = [NSBundle bundleWithPath: _path];
  
  UKNotNil(appBundle);
  UKNotNil([[appBundle infoDictionary] objectForKey: @"ApplicationName"]);
}
#endif

- (NSImage *) _cachedIconForVariant: (IKIconVariant)variant
{
  NSString *path;
  NSString *pathComponent;
  BOOL isDir;
  NSBundle *appBundle;

  path = [self _compositedIconsPath];

  switch (variant)
    {
      case IKIconVariantDocument:
        path = [path stringByAppendingPathComponent: DOCUMENT_PATH_COMPONENT];
        break;
        
      case IKIconVariantPlugin:
        path = [path stringByAppendingPathComponent: PLUGIN_PATH_COMPONENT];
        break;
    
      default:
        // Pathological case
        return nil;
    }
  
  if (_identifier == nil)
    {
      appBundle = [NSBundle bundleWithPath: _path]; 
      _identifier = [appBundle bundleIdentifier];
    }
  
  if (_identifier == nil)
    {
      _identifier = [[appBundle infoDictionary] objectForKey: @"ApplicationName"];
    }
  
  /*
  if (_identifier == nil)
    {
      NSLog(@"Impossible to look for the application composited icons cache \
        because the application has no bundle identifier");
      return;
    }
  */
    
  pathComponent = [[_identifier md5Hash] stringByAppendingPathExtension: @"tiff"];
  path = [path stringByAppendingPathComponent: pathComponent];
  
  NSLog(@"Try to retrieve cached icon at path: %@", path);
  if ([fileManager fileExistsAtPath: path isDirectory: &isDir] && !isDir)
    return AUTORELEASE([[NSImage alloc] initWithContentsOfFile: path]);
  
  NSLog(@"Unable to retrieve or instantiate the icon cached at path: %@", path);
  return nil;
}

#ifdef HAVE_UKTEST
- (void) test_cacheIconForVariant
{
  NSString *path = [self _compositedIconsPath];
  NSFileManager *fm = [NSFileManager defaultManager];
  BOOL dir;
  
  UKNotNil(path);
  UKTrue([fm fileExistsAtPath: path isDirectory: &dir]);
  UKTrue(dir);
  
  [self _cacheIcon: [NSImage imageNamed: @"common_Unknown"] 
        forVariant: IKIconVariantDocument];
  
  UKNotNil(_identifier);
  UKStringsNotEqual(_identifier, @"");
  
  UKNotNil([_identifier md5Hash]);
  
  path = [path stringByAppendingPathComponent: @"Document"];
  path = [path stringByAppendingPathComponent: 
    [[_identifier md5Hash] stringByAppendingPathExtension: @"tiff"]];
  UKTrue([fm fileExistsAtPath: path isDirectory: &dir]);
  
  // FIXME: Think to remove the cached file just created in -releaseForTest
}
#endif

- (void) _cacheIcon: (NSImage *)icon forVariant: (IKIconVariant)variant
{
  NSString *path;
  NSString *pathComponent;
  NSData *data;
  BOOL isDir;
  NSBundle *appBundle;
  
  path = [self _compositedIconsPath];

  switch (variant)
    {
      case IKIconVariantDocument:
        path = [path stringByAppendingPathComponent: DOCUMENT_PATH_COMPONENT];
        break;
        
      case IKIconVariantPlugin:
        path = [path stringByAppendingPathComponent: PLUGIN_PATH_COMPONENT];
        break;
    
      default:
        // Pathological case
        return;
    }
    
  if ([fileManager fileExistsAtPath: path isDirectory: &isDir] == NO)
    {
      [self _buildDirectoryStructureForCompositedIconsCache];
    }
  else if (isDir == NO) // A file exists at this path, bad luck
    {
      NSLog(@"Impossible to create a directory named %@ at the path %@ \
        because there is already a file with this name", 
        [path lastPathComponent], [path stringByDeletingLastPathComponent]);
      return; 
    }
  
  if (_identifier == nil)
    {
      appBundle = [NSBundle bundleWithPath: _path];
      _identifier = [appBundle bundleIdentifier];
    }
  
  if (_identifier == nil)
    {
      _identifier = [[appBundle infoDictionary] objectForKey: @"ApplicationName"];
    }
  
  /*
  if (_identifier == nil)
    {
      NSLog(@"Impossible to look for the application composited icons cache \
        because the application has no bundle identifier");
      return;
    }
  */
  
  pathComponent = [[_identifier md5Hash] stringByAppendingPathExtension: @"tiff"]; 
  path = [path stringByAppendingPathComponent: pathComponent];
  data = [icon TIFFRepresentation];
  
  NSLog(@"Cache icon at path: %@", path);
  [data writeToFile: path atomically: YES];
}

#ifdef HAVE_UKTEST
- (void) test_buildDirectoryStructureForCompositedIconsCache
{
  NSString *path = [self _compositedIconsPath];
  NSFileManager *fm = [NSFileManager defaultManager];
  BOOL dir;
  
  UKNotNil(path);
  UKTrue([fm fileExistsAtPath: path isDirectory: &dir]);
  UKTrue(dir);
  
  UKTrue([self _buildDirectoryStructureForCompositedIconsCache]);
}
#endif

// FIXME: Rename _buildFoldersForCache
- (BOOL) _buildDirectoryStructureForCompositedIconsCache
{
  NSString *path;
  NSString *subpath;
  
  path = [self _compositedIconsPath];
  NSLog(@"Trying to create directory structure for cache at path: %@", path);
  
  if ([fileManager buildDirectoryStructureForPath: path] == NO)
    return NO;
  
  subpath = [path stringByAppendingPathComponent: DOCUMENT_PATH_COMPONENT];
  if ([fileManager checkWithEventuallyCreatingDirectoryAtPath: subpath] == NO)
    return NO;
  subpath = [path stringByAppendingPathComponent: PLUGIN_PATH_COMPONENT];
  if ([fileManager checkWithEventuallyCreatingDirectoryAtPath: subpath] == NO)
    return NO;
  
  NSLog(@"Successfully created directory structure for cache");
  return YES;
}

- (void) _obtainBundlePathIfNeeded
{
  /* When NSBundle will support bundleWithIdentifier method, this code should 
   * be activated
  if (_path == nil)
    {
      if (_identifier != nil)
        {
          NSBundle *bundle = [NSBundle bundleWithIdentifier: _identifier];
          if (bundle == nil)
            {
              NSLog(@"Impossible to retrieve a bundle with the identifier %@, 
                the identifier is probably not valid", _identifier);
              return nil;
            }
          _path = [bundle bundlePath];
        }
    }
   */
}
#ifdef HAVE_UKTEST
- (void) test_blankDocumentIcon
{
  UKNotNil([self _blankDocumentIcon]);
}
#endif

- (NSImage *) _blankDocumentIcon
{
  return [NSImage imageNamed: @"common_Unknown"];
}

#ifdef HAVE_UKTEST
- (void) test_blankPluginIcon
{
  //UKNotNil([self _blankPluginIcon]);
}
#endif

- (NSImage *) _blankPluginIcon
{
  return nil;
}

@end
