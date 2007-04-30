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

#import <IconKit/IKThumbnailProvider.h>
#import "NSString+MD5Hash.h"
#import <IconKit/IKIconProvider.h>
#import <IconKit/IKApplicationIconProvider.h>

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
    }
  
  return self;
}

/*
 * The two methods below implement an automated cache mechanism and a thumbnails
 * generator
 */

- (NSImage *) iconForURL: (NSURL *)url
{
  NSImage *icon;
  IKThumbnailProvider *thumbnailProvider = [IKThumbnailProvider sharedInstance];
  
  icon = [self _cachedIconForURL: url];
  // If the file has a custom icon, the icon is cached because custom icons are
  // stored in the cache
  
  if (icon != nil)
    return icon;
  
  //FIXME: Add code to handle file packages with isFilePackageAtPath: 
  
  if (_usesThumbnails)
    {
      NSImage *thumbnail;
      
      thumbnail = [thumbnailProvider thumbnailForURL: url size: IKThumbnailSizeNormal];
      [thumbnail setScalesWhenResized: YES];
      [thumbnail setSize: NSMakeSize(64, 64)];
      icon = thumbnail;
      [self _cacheThumbnailIcon: (NSImage *)icon forURL: url];
    }
  
  if (icon != nil)
    return icon;
  
  icon = [self defaultIconForURL: url];
  
  return icon;
}

- (NSImage *) iconForPath: (NSString *)path
{
  NSURL *url = [NSURL fileURLWithPath: path];
  
  return [self iconForURL: url];
}

- (NSImage *) defaultIconForURL: (NSURL *)url
{
  // The method can be overriden by the desktop environment to improve the implementation
  // or to better fit with its icons management/storage model.

  NSString *extension = [[url path] pathExtension];
  NSDictionary *extensionInfo = [workspace infoForExtension: extension];
  NSString *appPath = [workspace getBestAppInRole: nil forExtension: extension]; 
  NSImage *icon = [workspace _extIconForApp: appPath info: extensionInfo];
  
  if (icon != nil)
    return icon;

  return nil;
}

- (NSImage *) defaultIconForPath: (NSString *)path
{
  NSURL *url = [NSURL fileURLWithPath: path];
  
  return [self defaultIconForURL: url];
}

- (NSImage *) systemIconForURL: (NSURL *)url
{
  NSString *pathExt = [[url absoluteString] pathExtension];
  NSBundle *bundle = [NSBundle mainBundle];
  NSString *path = [bundle pathForResource: @"MimeMapping" ofType: @"plist"];
  NSString *plistString = [NSString stringWithContentsOfFile: path];
  id plist = [plistString propertyList];
  
  return [NSImage imageNamed: [plist objectForKey: pathExt]];  
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
