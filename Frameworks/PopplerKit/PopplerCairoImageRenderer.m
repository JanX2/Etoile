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

#import "PopplerCairoImageRenderer.h"
#import "PopplerFontManager.h"
#import "NSObject+PopplerObject.h"
#import "PopplerKitFunctions.h"

#include "bindings/poppler_cairo_img_renderer.h"

/**
 * Non-Public methods.
 */
@interface PopplerCairoImageRenderer (Private)
@end


@implementation PopplerCairoImageRenderer

+ (BOOL) isSupported
{
#ifdef HAVE_CAIRO
   return YES;
#else
   return NO;
#endif
}

- (id) initWithDocument: (PopplerDocument*)aDocument
{
#ifndef HAVE_CAIRO
   [NSException raise: PopplerException
               format: @"your version of PopplerKit does not support cairo!"];
   return nil;
#else
   NSAssert(aDocument, @"no document");
   
   self = [super init];
   if (self)
   {
      document = [aDocument retain];
      output_dev = poppler_cairo_img_device_create();
      NSAssert(output_dev, @"poppler_cairo_img_device_create failed");
      poppler_cairo_img_device_start_doc(output_dev, [document poppler_object]);
   }
   
   return self;
#endif
}

- (void) dealloc
{
#ifdef HAVE_CAIRO
   if (output_dev)
   {
      poppler_cairo_img_device_destroy(output_dev);
   }  
   [document release];
#endif
   [super dealloc];
}

- (id) renderPage: (PopplerPage*)aPage
           srcBox: (NSRect)aBox
            scale: (float)aScale
{
#ifndef HAVE_CAIRO
   [NSException raise: PopplerException
               format: @"your version of PopplerKit does not support cairo!"];
   return nil;
#else
   int rc;
   
   NSAssert(aPage, @"no page");
   NSAssert(aScale > 0.0, @"invalid scale");
   
   double hDPI = PopplerKitDPI().width * aScale;
   double vDPI = PopplerKitDPI().height * aScale;

   rc = poppler_cairo_img_device_display_slice(output_dev,
                                              [aPage poppler_object],
                                              [document poppler_object],
                                              hDPI, vDPI, PopplerKitDPI().width,
                                              0, // takes care of the page rotation itself
                                              NSMinX(aBox), NSMinY(aBox),
                                              NSWidth(aBox), NSHeight(aBox));
   NSAssert(rc, @"poppler_cairo_img_device_display_slice failed");
                                       
   unsigned char* cairoData;
   int cairoWidth, cairoHeight, cairoRowstride;
   rc = poppler_cairo_img_device_get_data(output_dev, &cairoData, &cairoWidth,
                                          &cairoHeight, &cairoRowstride);
   NSAssert(rc, @"poppler_cairo_img_device_get_data failed");
            
   NSBitmapImageRep* imageRep;
   imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes: NULL
                                                      pixelsWide: cairoWidth
                                                      pixelsHigh: cairoHeight
                                                   bitsPerSample: 8
                                                 samplesPerPixel: 3
                                                        hasAlpha: NO
                                                        isPlanar: NO
                                                  colorSpaceName: NSCalibratedRGBColorSpace
                                                     bytesPerRow: 3 * cairoWidth
                                                    bitsPerPixel: 8 * 3];
   [imageRep autorelease];

   unsigned char* repData = [imageRep bitmapData];
   rc = poppler_cairo_img_device_get_rgb(cairoData, &repData, cairoWidth,
                                         cairoHeight, cairoRowstride);
   NSAssert(rc, @"poppler_cairo_img_device_get_rgb failed");
   
   return imageRep;
#endif
}
            
- (id) renderPage: (PopplerPage*)aPage
            scale: (float)aScale
{
   return [self renderPage: aPage
                    srcBox: NSMakeRect(-1, -1, -1, -1)
                     scale: aScale];
}

@end


/* ----------------------------------------------------- */
/*  Category Private                                     */
/* ----------------------------------------------------- */

@implementation PopplerCairoImageRenderer (Private)
@end
