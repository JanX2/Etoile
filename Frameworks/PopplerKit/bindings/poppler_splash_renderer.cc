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

#include <stdio.h>
#include <stdlib.h>
#include "poppler_splash_renderer.h"
#include "poppler.h"
#include <PDFDoc.h>
#include <Page.h>
#include <goo/GooString.h>
#include <SplashOutputDev.h>
#include <splash/SplashBitmap.h>

#define PDF_DOC(obj) static_cast<PDFDoc*>(obj)
#define PAGE(obj) static_cast<Page*>(obj)
#define SPLASH_DEV(obj) static_cast<SplashOutputDev*>(obj)
#define SPLASH_BITMAP(obj) static_cast<SplashBitmap*>(obj)

void* poppler_splash_device_create(int bg_red, int bg_green, int bg_blue)
{  
   BEGIN_SYNCHRONIZED;
      SplashColor white;
      white.rgb8 = splashMakeRGB8(bg_red, bg_green, bg_blue);
      void* splashDevice = new SplashOutputDev(splashModeRGB8, gFalse, white);
   END_SYNCHRONIZED;
   
   return splashDevice;
}

void poppler_splash_device_start_doc(void* output_dev, void* poppler_document)
{
   if (!output_dev || !poppler_document)
   {
     return;
   }
    
   SYNCHRONIZED(SPLASH_DEV(output_dev)->startDoc(PDF_DOC(poppler_document)->getXRef()));
}

void poppler_splash_device_destroy(void* output_dev)
{
   if (!output_dev)
   {
      return;
   }
   
   delete SPLASH_DEV(output_dev);
}

int poppler_splash_device_display_slice(void* output_dev, void* poppler_page,
                                        void* poppler_document,
                                        float hDPI, float vDPI, int rotate,
                                        float sliceX, float sliceY,
                                        float sliceW, float sliceH)
{
   if (!output_dev || !poppler_page || !poppler_document)
   {
      return 0;
   }

   
   SYNCHRONIZED(PAGE(poppler_page)->displaySlice(SPLASH_DEV(output_dev),
                                                 (double)hDPI, (double)vDPI,
                                                 rotate,
                                                 gTrue, // Crop
                                                 (int)sliceX, (int)sliceY,
                                                 (int)sliceW, (int)sliceH,
                                                 NULL, // Links
                                                 PDF_DOC(poppler_document)->getCatalog()));

   return 1;
}

int poppler_splash_device_get_bitmap(void* output_dev, void** bitmap,
                                     int* width, int* height)
{
   if (!output_dev)
   {
      return 0;
   }
   
   SplashBitmap* _bitmap = SPLASH_DEV(output_dev)->getBitmap();
   *width = _bitmap->getWidth();
   *height = _bitmap->getHeight();
   *bitmap = _bitmap;

   return 1;
}

int poppler_splash_device_get_rgb(void* bitmap, unsigned char** data)
{
   if (!bitmap)
   {
      return 0;
   }

   SplashRGB8*     rgb8;
   unsigned char*  dataPtr;

   rgb8 = SPLASH_BITMAP(bitmap)->getDataPtr().rgb8;

   dataPtr = *data;
   for (int row = 0; row < SPLASH_BITMAP(bitmap)->getHeight(); row++)
   {
      for (int col = 0; col < SPLASH_BITMAP(bitmap)->getWidth(); col++)
      {
         *dataPtr++ = splashRGB8R(*rgb8);
         *dataPtr++ = splashRGB8G(*rgb8);
         *dataPtr++ = splashRGB8B(*rgb8);
         ++rgb8;
      }
   }
   
   return 1;
}
