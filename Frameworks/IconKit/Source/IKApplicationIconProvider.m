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

#import "IKCompositor.h"
#import "IKCompositorOperation.h"
#import "NSString+MD5Hash.h"
#import "NSFileManager+IconKit.h"
#import "IKApplicationIconProvider.h"

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
  if (self = [IKApplicationIconProvider class])
    {
      workspace = [NSWorkspace sharedWorkspace];
      fileManager = [NSFileManager defaultManager];
    }
}

/*
 * Init methods
 */

- (id) initWithBundlePath: (NSString *)path
{
  if ((self = [super init]) != nil)
    {
      if (path == nil)
        {
          // FIXME: raise exception
          return nil;
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
          // FIXME: raise exception
          return nil;
        }
      ASSIGN(_identifier, identifier);
      return self;
    }
    
  return nil;
}

// ---

- (NSImage *) applicationIcon
{
  [self _obtainBundlePathIfNeeded];
  
  if (_path != nil)   
    return [workspace appIconForApp: _path];
  
  return nil;
}

/*
 * GNUstep compatible implementation, but should be overrided in favor of an 
 * improved implementation in Etoile with the ExtendedWorkspaceKit
 */
- (NSImage *) documentIconForExtension: (NSString *)extension
{
  // We do not use -_iconForExtension: or -iconFoFileType because we don't want
  // the workspace behavior, we want a custom behavior
  
  NSDictionary *extensionInfo;
  NSImage *icon = nil;
  
  [self _obtainBundlePathIfNeeded];
  
  if (_path == nil)
    {
      return nil;
      // Pathological case, should never happen
    }
  
  // We try to retrieve the special icon associated with the extension for the 
  // application matched by _path
  extensionInfo = [workspace infoForExtension: extension];
  if (extensionInfo != nil)
    {
      icon = [workspace _extIconForApp: _path info: extensionInfo];
    }
  
  // We are ignoring voluntarly the custom icon which can be set by the user for
  // the files with a specific extension. See NSWorkspace 
  // -setBestIcon:forExtension: -getBestIconForExtension: methods
  // We are also ignoring woluntarly the default application (with its icons set)
  // associated with the extension
  
  if (icon != nil)
    return icon;
  
  // Check the cache for composited icons
  icon = [self _cachedIconForVariant: IKIconVariantDocument];
  if (icon != nil)
    return icon;
    
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

- (void) invalidCache
{
  NSString *path;
  NSString *subpath;
  NSString *pathComponent = [_path md5Hash];
  BOOL result;
  BOOL isDir;
  
  pathComponent = [pathComponent stringByAppendingPathExtension: @"tiff"];
  
  path = [self _compositedIconsPath];  
  
  // We remove the composited icon in the Document directory of the cache
  subpath = [path stringByAppendingPathComponent: @"Document"];
  subpath = [subpath stringByAppendingPathComponent: pathComponent];
  
  [fileManager removeFileAtPath: subpath handler: nil];
  if (result == NO)
    {
      NSLog(@"Impossible to invalid document composited icon cache for the \
        application %@", _path);
    }
  
  // We remove the composited icon in the Plugin directory of the cache  
  subpath = [path stringByAppendingPathComponent: @"Plugin"];
  subpath = [subpath stringByAppendingPathComponent: pathComponent];
  
  [fileManager removeFileAtPath: subpath handler: nil];
  if (result == NO)
    {
      NSLog(@"Impossible to invalid plugin composited icon cache for the \
        application %@", _path);
    }
}

- (void) invalidCacheAll
{
  NSString *path = [self _compositedIconsPath];
  BOOL isDir;
  BOOL result = NO;
  
  result = [fileManager removeFileAtPath: path handler: nil];
  
  if (result == NO)
    {
      NSLog(@"Impossible to invalid the composited icons cache");
    }
}

- (void) recache
{
  NSImage *icon;
  
  [self invalidCache];
  
  icon = [self _compositeIconForVariant: IKIconVariantDocument];
  if (icon != nil)
    [self _cacheIcon: icon forVariant: IKIconVariantDocument];
  
  icon = [self _compositeIconForVariant: IKIconVariantPlugin];
  if (icon != nil)
    [self _cacheIcon: icon forVariant: IKIconVariantPlugin];
}

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

- (NSString *) _compositedIconsPath
{
  NSArray *locations = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSLocalDomainMask, YES);
  NSString *path;
  
  if ([locations count] == 0)
    {
      // Raise exception
    }
  
  path = [locations objectAtIndex: 0];    
  path = [path stringByAppendingPathComponent: @"Caches"];
  path = [path stringByAppendingPathComponent: @"IconKit"];
  return [path stringByAppendingPathComponent: @"Composited icons"];
}

- (NSImage *) _cachedIconForVariant: (IKIconVariant)variant
{
  NSString *path;
  NSString *pathComponent;
  BOOL isDir;

  path = [self _compositedIconsPath];

  switch (variant)
    {
      case IKIconVariantDocument:
        path = [path stringByAppendingPathComponent: @"Document"];
        break;
        
      case IKIconVariantPlugin:
        path = [path stringByAppendingPathComponent: @"Plugin"];
        break;
    
      default:
        // Pathological case
        return;
    }
  
  if (_identifier == nil)
    {
      if (_path != nil)
        _identifier = [[NSBundle bundleWithPath: _path] bundleIdentifier];
    }
  
  if (_identifier == nil)
    {
      NSLog(@"Immpossible to look for the application composited icons cache \
        because the application has no bundle identifier");
      return nil;
    }
    
  pathComponent = [[_identifier md5Hash] stringByAppendingPathExtension: @"tiff"];
  path = [path stringByAppendingPathComponent: pathComponent];
  
  if ([fileManager fileExistsAtPath: path isDirectory: &isDir] && !isDir)
    return AUTORELEASE([[NSImage alloc] initWithContentsOfFile: path]);
    
  return nil;
}

- (void) _cacheIcon: (NSImage *)icon forVariant: (IKIconVariant)variant
{
  NSString *path;
  NSString *pathComponent;
  NSBitmapImageRep *rep;
  NSData *data;
  BOOL isDir;
  
  path = [self _compositedIconsPath];

  switch (variant)
    {
      case IKIconVariantDocument:
        path = [path stringByAppendingPathComponent: @"Document"];
        break;
        
      case IKIconVariantPlugin:
        path = [path stringByAppendingPathComponent: @"Plugin"];
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
      if (_path != nil)
        _identifier = [[NSBundle bundleWithPath: _path] bundleIdentifier];
    }
  
  if (_identifier == nil)
    {
      NSLog(@"Impossible to look for the application composited icons cache \
        because the application has no bundle identifier");
      return;
    }
  
  pathComponent = [[_identifier md5Hash] stringByAppendingPathExtension: @"tiff"]; 
  path = [path stringByAppendingPathComponent: [_identifier md5Hash]];
  data = [icon TIFFRepresentation];
  [data writeToFile: path atomically: YES];
}

- (BOOL) _buildDirectoryStructureForCompositedIconsCache
{
  NSString *path;
  NSString *subpath;
  
  path = [self _compositedIconsPath];
  
  if ([fileManager buildDirectoryStructureForPath: path] == NO)
    return NO;
    
  subpath = [path stringByAppendingPathComponent: @"Document"];
  if ([fileManager checkWithEventuallyCreatingDirectoryAtPath: subpath] == NO)
    return NO;
  subpath = [path stringByAppendingPathComponent: @"Plugin"];
  if ([fileManager checkWithEventuallyCreatingDirectoryAtPath: subpath] == NO)
    return NO;
    
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

- (NSImage *) _blankDocumentIcon
{
  return nil;
}

- (NSImage *) _blankPluginIcon
{
  return nil;
}

@end
