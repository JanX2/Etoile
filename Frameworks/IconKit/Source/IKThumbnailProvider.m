/*
	IKThumbnailProvider.m

	IconKit thumbnail provider class which permits to obtain and store thumbnails  
	with a standard architecture available for the GNUstep applications (it is 
	possible to store custom thumbnails)
	IKThumbnailProvider is Freedesktop compatible
	
	Copyright (C) 2004 Nicolas Roard <nicolas@roard.com>
	                   Quentin Mathe <qmathe@club-internet.fr>

	Author:   Nicolas Roard <nicolas@roard.com>
	          Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2004

    This application is free software; you can redistribute it and/or 
    modify it under the terms of the 3-clause BSD license. See COPYING.
*/

#import "IKCompat.h"
#import "NSFileManager+IconKit.h"
#import "NSString+MD5Hash.h"
#import <IconKit/IKThumbnailProvider.h>

static IKThumbnailProvider *thumbnailProvider = nil;
static NSFileManager *fileManager = nil;

@interface IKThumbnailProvider (Private)
- (BOOL) _buildDirectoryStructureForThumbnailsCache;
- (NSImage *) _cachedThumbnailForURL: (NSURL *)url size: (IKThumbnailSize)thumbnailSize;
- (void) _cacheThumbnail: (NSImage *)thumbnail forURL: (NSURL *)url;
- (NSString *) _thumbnailsPath;
@end

@implementation IKThumbnailProvider

/*
 * Class methods
 */
 
/* Not needed
+ (void) initialize
{
  if (self = [IKThumbnailProvider class])
    {
      fileManager = [NSFileManager defaultManager];
    }
}
*/

+ (IKThumbnailProvider *) sharedInstance
{
  if (thumbnailProvider == nil)
    {
      thumbnailProvider = [IKThumbnailProvider alloc];
    }     
  
  thumbnailProvider = [thumbnailProvider init];
  
  return thumbnailProvider;
}   

/*
 * Init methods
 */
- (id) init
{
  if (thumbnailProvider != self)
    {
      AUTORELEASE(self);
      return RETAIN(thumbnailProvider);
    }
  
  if ((self = [super init])  != nil)
    {
      fileManager = [NSFileManager defaultManager];
    }
  
  return self;
}

/*
 * Thumbnails are stored in ~/GNUstep/Library/Caches/IconKit/Thumbnails.
 * For Freedesktop compatibility, we add ~/.thumbnails soft link to the default
 * path.
 * The directory structure is
 * Thumbnails/normal which contains thumbnails with 128*128 size
 * Thumbnails/large which contains thumbnails with 256*256 size
 * Thumbnails/fail which tracks thumbnails creation errors.
 * Each thumbnail name is a MD5 hash of the original file URL.
 */

- (NSImage *) thumbnailForURL: (NSURL *)url size: (IKThumbnailSize)thumbnailSize
{
  NSImage *thumbnail;
  
  // We check the cache first
  
  thumbnail = [self _cachedThumbnailForURL: url size: thumbnailSize];
  if (thumbnail != nil)
    return thumbnail;
  
  // If the cache is empty, we create the thumbnail
  
  thumbnail =  [[NSImage alloc] initWithContentsOfURL: url];
  [thumbnail setScalesWhenResized: YES]; 
  switch (thumbnailSize)
    {
      case IKThumbnailSizeNormal:
        [thumbnail setSize: NSMakeSize(128, 128)];
      case IKThumbnailSizeLarge:
        [thumbnail setSize: NSMakeSize(256, 256)];
    }
   
  // And we cache the thumbnail  
  [self _cacheThumbnail: thumbnail forURL: url];  
  
  // Now we can return the new thumbnail
  return thumbnail;
}

- (NSImage *) thumbnailForPath: (NSString *)path size: (IKThumbnailSize)thumbnailSize
{
  NSURL *url = [NSURL fileURLWithPath: path];
  
  return [self thumbnailForURL: url size: thumbnailSize];
}

- (void) setThumbnail: (NSImage *)thumbnail forURL: (NSURL *)url
{
  [self invalidCacheForURL: url];
  [self _cacheThumbnail: thumbnail forURL: url];
}

- (void) setThumbnail: (NSImage *)thumbnail forPath: (NSString *)path
{
  NSURL *url = [NSURL fileURLWithPath: path];
  
  [self setThumbnail: thumbnail forURL: url];
}

- (void) recacheForURL: (NSURL *)url
{
  NSImage *thumbnail;
  
  // FIXME: should recreate the cache only for the previously cached thumbnail 
  // size
  
  [self invalidCacheForURL: url];
  
  thumbnail = [self _cachedThumbnailForURL: url size: IKThumbnailSizeNormal];
  if (thumbnail != nil)
    [self _cacheThumbnail: thumbnail forURL: url];
  
  thumbnail = [self _cachedThumbnailForURL: url size: IKThumbnailSizeLarge];
  if (thumbnail != nil)
    [self _cacheThumbnail: thumbnail forURL: url];
}

- (void) recacheForPath: (NSString *)path
{
  NSURL *url = [NSURL fileURLWithPath: path];
  
  [self recacheForURL: url];
}

- (void) invalidCacheForURL: (NSURL *)url
{
  NSString *path;
  NSString *subpath;
  NSString *pathComponent = [url absoluteString];
  NSString *pathComponentHash = [pathComponent md5Hash];
  BOOL result;
  
  path = [self _thumbnailsPath];  
  subpath = [path stringByAppendingPathComponent: @"large"];
  subpath = [subpath stringByAppendingPathComponent: pathComponentHash];
  subpath = [subpath stringByAppendingPathExtension: @"tif"];
  
  result = [fileManager removeFileAtPath: subpath handler: nil];
  if (result == NO)
    {
      NSLog(@"Impossible to invalid large thumbnail cache for URL %@", 
        pathComponent);
    }
    
  subpath = [path stringByAppendingPathComponent: @"normal"];
  subpath = [subpath stringByAppendingPathComponent: pathComponentHash];
  subpath = [subpath stringByAppendingPathExtension: @"tif"];
  
  result = [fileManager removeFileAtPath: subpath handler: nil];
  if (result == NO)
    {
      NSLog(@"Impossible to invalid normal thumbnail cache for URL %@", 
        pathComponent);
    }
}

- (void) invalidCacheForPath: (NSString *)path
{
  NSURL *url = [NSURL fileURLWithPath: path];
  
  [self invalidCacheForURL: url];
}

- (void) invalidCacheAll
{
  NSString *path = [self _thumbnailsPath];
  BOOL result = NO;
  
  result = [fileManager removeFileAtPath: path handler: nil];
      
  if (result == NO)
    {
      NSLog(@"Impossible to invalid the complete thumbnails cache");
    }
}

/*
 * Private methods
 */
 
- (NSString *) _thumbnailsPath
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
  return [path stringByAppendingPathComponent: @"Thumbnails"];
}

- (NSImage *) _cachedThumbnailForURL: (NSURL *)url size: (IKThumbnailSize)thumbnailSize
{
  NSString *path;
  NSString *pathComponent;
  BOOL isDir;

  path = [self _thumbnailsPath];

  if (thumbnailSize == IKThumbnailSizeLarge)
    {
      path = [path stringByAppendingPathComponent: @"large"];
    }
  else if (thumbnailSize == IKThumbnailSizeNormal)
    {
      path = [path stringByAppendingPathComponent: @"normal"];
    }
  else
    {
      return nil; // Pathological case
    }
    
  if (![fileManager fileExistsAtPath: path isDirectory: &isDir] || !isDir)
    {
      return nil;
    }
  
  pathComponent = [[[url absoluteString] md5Hash] stringByAppendingPathExtension: @"tif"];
  path = [path stringByAppendingPathComponent: pathComponent];
  
  if ([fileManager fileExistsAtPath: path isDirectory: &isDir] && !isDir)
    return AUTORELEASE([[NSImage alloc] initWithContentsOfFile: path]);
  
  return nil;
}

- (void) _cacheThumbnail: (NSImage *)thumbnail forURL: (NSURL *)url
{
  NSString *path;
  NSBitmapImageRep *rep;
  BOOL isDir;
  NSData *data;
  
  path = [self _thumbnailsPath];

  if (NSEqualSizes([thumbnail size], NSMakeSize(256, 256)))
    {
      path = [path stringByAppendingPathComponent: @"large"];
    }
  else if (NSEqualSizes([thumbnail size], NSMakeSize(128, 128)))
    {
      path = [path stringByAppendingPathComponent: @"normal"];
    }
  else
    {
      return; // Pathological case
    }
    
  if ([fileManager fileExistsAtPath: path isDirectory: &isDir] == NO)
    {
      [self _buildDirectoryStructureForThumbnailsCache];
    }
  else if (isDir == NO) // A file exists at this path, bad luck
    {
      NSLog(@"Impossible to create a directory named %@ at the path %@ \
        because there is already a file with this name", 
        [path lastPathComponent], [path stringByDeletingLastPathComponent]);
      return; 
    }
    
  rep = [[NSBitmapImageRep alloc] initWithData: [thumbnail TIFFRepresentation]]; 
  data = [rep representationUsingType: NSPNGFileType properties: nil];
  
  path = [path stringByAppendingPathComponent: [[url absoluteString] md5Hash]];
  [data writeToFile: path atomically: YES];
}

- (BOOL) _buildDirectoryStructureForThumbnailsCache
{
  NSString *path;
  NSString *subpath;
  
  path = [self _thumbnailsPath];
  
  if ([fileManager buildDirectoryStructureForPath: path] == NO)
    return NO;
    
  subpath = [path stringByAppendingPathComponent: @"large"];
  if ([fileManager checkWithEventuallyCreatingDirectoryAtPath: subpath] == NO)
    return NO;
  subpath = [path stringByAppendingPathComponent: @"normal"];
  if ([fileManager checkWithEventuallyCreatingDirectoryAtPath: subpath] == NO)
    return NO;
  subpath = [path stringByAppendingPathComponent: @"fail"];
  if ([fileManager checkWithEventuallyCreatingDirectoryAtPath: subpath] == NO)
    return NO;
    
  return YES;
}

@end
