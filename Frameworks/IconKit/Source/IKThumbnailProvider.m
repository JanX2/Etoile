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

#import <libpng/png.h>
#import "NSFileManager+IconKit.h"
#import "NSString+MD5Hash.h"
#import "IKThumbnailProvider.h"

static IKThumbnailProvider *thumbnailProvider = nil;
static NSFileManager *fileManager = nil;

@interface IKThumbnailProvider (Private)
- (BOOL) _buildDirectoryStructureForThumbnailsCache;
- (NSImage *) _cachedThumbnailForURL: (NSURL *)url size: (IKThumbnailSize)thumbnailSize;
- (void) _cacheThumbnail: (NSImage *)thumbnail forURL: (NSURL *)url;
- (NSData *) _PNGWithBitmapImageRep: (NSBitmapImageRep *)rep;
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
  BOOL isDir;
  
  path = [self _thumbnailsPath];  
  subpath = [path stringByAppendingPathComponent: @"large"];
  subpath = [subpath stringByAppendingPathComponent: pathComponentHash];
  subpath = [subpath stringByAppendingPathExtension: @"png"];
  
  [fileManager removeFileAtPath: subpath handler: nil];
  if (result == NO)
    {
      NSLog(@"Impossible to invalid large thumbnail cache for URL %@", 
        pathComponent);
    }
    
  subpath = [path stringByAppendingPathComponent: @"normal"];
  subpath = [subpath stringByAppendingPathComponent: pathComponentHash];
  subpath = [subpath stringByAppendingPathExtension: @"png"];
  
  [fileManager removeFileAtPath: subpath handler: nil];
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
  BOOL isDir;
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
  NSFileManager *fileManager = [NSFileManager defaultManager];
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
      return; // Pathological case
    }
    
  if (![fileManager fileExistsAtPath: path isDirectory: &isDir] || !isDir)
    {
      return nil;
    }
  
  pathComponent = [[[url absoluteString] md5Hash] stringByAppendingPathExtension: @"png"];
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
  // data = [rep representationUsingType: NSPNGFileType properties: nil];
  data = [self _PNGWithBitmapImageRep: rep];
  
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

/*
 * Still to be implemented
 *
- (void) _writePNGTextWithValue: (NSString *)value forKey: (NSString *)key
{
  png_charp keyPNG = [[key dataUsingEncoding: NSISOLatin1StringEncoding] bytes];
  png_charp textPNG = [[value dataUsingEncoding: NSISOLatin1StringEncoding] bytes];
}

- (NSDictionary *) _readPNGText
{

}
 */

void user_write_data(png_structp png_ptr, png_bytep data, png_size_t length)
{
  NSData *objectData = png_get_io_ptr(png_ptr);
  
  objectData = [NSData dataWithBytes: data length: length];
}

- (NSData *) _PNGWithBitmapImageRep: (NSBitmapImageRep *)rep
{
  png_structp png_ptr;
  png_infop info_ptr;
  NSString *colorSpaceName;
  BOOL alpha = NO;
  BOOL gray = NO;
  BOOL color = NO;
  voidp output;
  NSData *data;

  /* Create and initialize the png_struct with the desired error handler
     functions.  If you want to use the default stderr and longjump method,
     you can supply NULL for the last three parameters.  We also check that
     the library version is compatible in case we are using dynamically
     linked libraries.
   */
  png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);

  if (!png_ptr)
  {
    // We have encountered an error
    return nil;
  }

  info_ptr = png_create_info_struct(png_ptr);
  if (!info_ptr)
  {
    // We have encountered an error
    png_destroy_write_struct(&png_ptr,  (png_infopp)NULL);
    return nil;
  }

  /* set error handling */
  if (setjmp(png_ptr->jmpbuf))
  {
    /* If we get here, we had a problem reading the file */
    png_destroy_write_struct(&png_ptr,  (png_infopp)NULL);
    return nil;
  }
   
  /* set up the output control if you are using standard C streams */
  // png_init_io(png_ptr, fp);
  
  /* if you are using replacement write functions, here you would call */
   png_set_write_fn(png_ptr, data, (png_rw_ptr)user_write_data, NULL);
  /* where io_ptr is a structure you want available to the callbacks */
  
  /* if you are using replacement message functions, here you would call */
  // png_set_message_fn(png_ptr, (void *)msg_ptr, user_error_fn, user_warning_fn);
  /* where msg_ptr is a structure you want available to the callbacks */

  /* set the file information here */
  info_ptr->width = [rep pixelsWide];
  info_ptr->height = [rep pixelsHigh];
  info_ptr->rowbytes = [rep bytesPerRow];
   
  colorSpaceName = [rep colorSpaceName];
  alpha = [rep hasAlpha];
  
  if ([colorSpaceName isEqualToString: NSCalibratedBlackColorSpace])
    {
      [rep setColorSpaceName: NSCalibratedWhiteColorSpace];
    }
  else if ([colorSpaceName isEqualToString: NSDeviceBlackColorSpace])
    {
      [rep setColorSpaceName: NSDeviceWhiteColorSpace];
    }
  else if ([colorSpaceName isEqualToString: NSDeviceCMYKColorSpace])
    {
      [rep setColorSpaceName: NSDeviceRGBColorSpace];
    }
  else if ([colorSpaceName isEqualToString: NSCustomColorSpace])
  // FIXME: not sure that the right thing to do
    {
      [rep setColorSpaceName: NSCalibratedRGBColorSpace];
    }
 
  if ([colorSpaceName isEqualToString: NSCalibratedWhiteColorSpace]
    || [colorSpaceName isEqualToString: NSDeviceWhiteColorSpace])
    {
      if (alpha)
        {
          info_ptr->color_type =  PNG_COLOR_TYPE_GRAY_ALPHA;
        }
      else
        {
          info_ptr->color_type = PNG_COLOR_TYPE_GRAY;
        }
      gray = YES;
    }
  else if ([colorSpaceName isEqualToString: NSCalibratedRGBColorSpace]
    || [colorSpaceName isEqualToString: NSDeviceRGBColorSpace])
    {
      if (alpha)
        {
          info_ptr->color_type =  PNG_COLOR_TYPE_RGB_ALPHA;
        }
      else
        {
          info_ptr->color_type = PNG_COLOR_TYPE_RGB;
        }
      color = YES;
    }
  else if ([colorSpaceName isEqualToString: NSNamedColorSpace])
    {
      // FIXME: to implement, probably with PNG_COLOR_TYPE_PALETTE
    }
    
  info_ptr->channels = [rep samplesPerPixel];
  info_ptr->bit_depth = [rep bitsPerSample];

  /* set the palette if there is one */
  // info_ptr->valid |= PNG_INFO_PLTE;
  // info_ptr->palette = malloc(256 * sizeof (png_color));
  // info_ptr->num_palette = 256;
  // ... set palette colors ...
  
  /* optional significant bit chunk */
  // info_ptr->valid |= PNG_INFO_sBIT;  
  /* if we are dealing with a grayscale image then */
  // if (gray)
  //   info_ptr->sig_bit.gray = true_bit_depth;
  /* otherwise, if we are dealing with a color image then */
  /*
  if (color)
    {
      info_ptr->sig_bit.red = true_red_bit_depth;
      info_ptr->sig_bit.green = true_green_bit_depth;
      info_ptr->sig_bit.blue = true_blue_bit_depth;
    }
   */
  /* if the image has an alpha channel then */
  // if (alpha)
  //   info_ptr->sig_bit.alpha = true_alpha_bit_depth;
  
  /* optional gamma chunk is strongly suggested if you have any guess
     as to the correct gamma of the image */
  // info_ptr->valid |= PNG_INFO_gAMA;
  // info_ptr->gamma = gamma;

   /* other optional chunks like cHRM, bKGD, tRNS, tEXt, tIME, oFFs, pHYs, */

   /* write the file header information */
   png_write_info(png_ptr, info_ptr);

   /* set up the transformations you want.  Note that these are
      all optional.  Only call them if you want them */

   /* invert monocrome pixels */
   // png_set_invert(png_ptr);

   /* shift the pixels up to a legal bit depth and fill in
      as appropriate to correctly scale the image */
   // png_set_shift(png_ptr, &(info_ptr->sig_bit));

   /* pack pixels into bytes */
   // png_set_packing(png_ptr);

   /* flip bgr pixels to rgb */
   // png_set_bgr(png_ptr);

   /* swap bytes of 16 bit files to most significant bit first */
   // png_set_swap(png_ptr);

   /* get rid of filler bytes, pack rgb into 3 bytes.  The
      filler number is not used. */
   // png_set_filler(png_ptr, 0, PNG_FILLER_BEFORE);

  /* turn on interlace handling if you are not using png_write_image() */
  //if (interlacing)
  //  number_passes = png_set_interlace_handling(png_ptr);
  //else
  //  number_passes = 1;

  /* the easiest way to write the image (you may choose to allocate the
    memory differently, however) */
  //png_byte row_pointers[info_ptr->height][info_ptr->width];
  
  int i;
  int height = [rep pixelsHigh];
  int bytes_per_row = [rep bytesPerRow];
  png_bytep buf;
  png_bytep row_pointers[height];  
  
  [rep getBitmapDataPlanes: &buf];
  
  for (i = 0; i < height; i++)
    row_pointers[i] = buf + i * bytes_per_row;
    
  png_write_image(png_ptr, row_pointers);

  /* the other way to write the image - deal with interlacing */

  //for (pass = 0; pass < number_passes; pass++)
  //  {
  //    /* Write a few rows at a time. */
  //    png_write_rows(png_ptr, row_pointers, number_of_rows);

        /* If you are only writing one row at a time, this works */
  //    for (y = 0; y < height; y++)
  //      {
  //        png_bytep row_pointers = row[y];
  //        png_write_rows(png_ptr, &row_pointers, 1);
  //      }
  //  }

  /* You can write optional chunks like tEXt, tIME at the end as well.
   * Note that if you wrote tEXt or zTXt chunks before the image, and
   * you aren't writing out more at the end, you have to set
   * info_ptr->num_text = 0 or they will be written out again.
   */

  /* write the rest of the file */
  png_write_end(png_ptr, info_ptr);

  /* if you malloced the palette, free it here */
  //if (info_ptr->palette)
  //  free(info_ptr->palette);

  /* if you allocated any text comments, free them here */

  /* clean up after the write, and free any memory allocated */
  png_destroy_write_struct(&png_ptr,  (png_infopp)NULL);

  /* that's it */
  return data;
}

@end
