/*
 * Copyright (C) 2004  Stefan Kleine Stegemann
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "PopplerDirectBufferedRenderer.h"
#import "PopplerDocument+Rendering.h"

/**
 * Non-Public methods.
 */
@interface PopplerDirectBufferedRenderer (Private)
- (BOOL) _cachedImageMatchesPage: (PopplerPage*)aPage
                          srcBox: (NSRect)aBox
                           scale: (float)aScale;
- (void) _cacheImage: (NSImageRep*)anImage
             forPage: (PopplerPage*)aPage
              srcBox: (NSRect)aBox
               scale: (float)aScale;
- (NSImageRep*) _cachedImage;
@end


@implementation PopplerDirectBufferedRenderer

- (id) initWithDocument: (PopplerDocument*)aDocument
{
   return [self initWithRenderer: [aDocument bufferedRenderer]];
}

- (id) initWithRenderer: (id<PopplerBufferedRenderer>)aRenderer
{
   NSAssert(aRenderer, @"no renderer");
   
   self = [super init];
   if (self)
   {
      bufferedRenderer = [(NSObject*)aRenderer retain];
      lastImage = nil;
      lastPageIndex = 0;
      lastScale = 0.0;
      lastSrcBox = NSZeroRect;
   }
   
   return self;
}

- (void) dealloc
{
   [lastImage release];
   [(NSObject*)bufferedRenderer release];
   [super dealloc];
}

- (void) drawPage: (PopplerPage*)aPage
           srcBox: (NSRect)aBox
          atPoint: (NSPoint)aPoint
            scale: (float)aScale
{
   NSAssert(aPage, @"no page");

   NSImageRep* image;
   if ([self _cachedImageMatchesPage: aPage srcBox: aBox scale: aScale])
   {
      image = [self _cachedImage];
   }
   else
   {
      image = [bufferedRenderer renderPage: aPage srcBox: aBox scale: aScale];
      [self _cacheImage: image forPage: aPage srcBox: aBox scale: aScale];
   }
   
   NSAssert(image, @"no image");
   [image drawAtPoint: aPoint];
   
   // DEBUG:
   //NSData* tiffData = nil;
   //tiffData = [image TIFFRepresentation];
   //[tiffData writeToFile: @"/Users/stefan/last-rendered.tiff" atomically: NO];
}
            
- (void) drawPage: (PopplerPage*)aPage
          atPoint: (NSPoint)aPoint
            scale: (float)aScale
{
   [self drawPage: aPage
           srcBox: NSMakeRect(-1, -1, -1, -1)
          atPoint: aPoint
            scale: aScale];
}

@end


/* ----------------------------------------------------- */
/*  Category Private                                     */
/* ----------------------------------------------------- */

@implementation PopplerDirectBufferedRenderer (Private)

- (BOOL) _cachedImageMatchesPage: (PopplerPage*)aPage
                          srcBox: (NSRect)aBox
                           scale: (float)aScale
{
   NSAssert(aPage, @"nil page");

   if (!lastImage)
   {
      return NO;
   }
   
   return NSEqualRects(lastSrcBox, aBox) &&
          (lastScale == aScale) &&
          ([aPage index] == lastPageIndex);
}

- (void) _cacheImage: (NSImageRep*)anImage
             forPage: (PopplerPage*)aPage
              srcBox: (NSRect)aBox
               scale: (float)aScale
{
   NSAssert(aPage, @"nil page");
   
   [lastImage release];
   lastImage = [anImage retain];
   
   lastPageIndex = [aPage index];
   lastSrcBox = aBox;
   lastScale = aScale;
}

- (NSImageRep*) _cachedImage
{
   return lastImage;
}

@end
