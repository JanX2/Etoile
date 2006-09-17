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
#include "poppler_cairo_img_renderer.h"
#include "poppler.h"
#include <PDFDoc.h>
#include <Page.h>
#include <goo/GooString.h>
#include <CairoOutputDev.h>

#define PDF_DOC(obj) static_cast<PDFDoc*>(obj)
#define PAGE(obj) static_cast<Page*>(obj)
#define CAIRO_DEV_IMG(obj) static_cast<CairoImageDev*>(obj)

#ifndef MAX
#define MAX(a,b) (((a)>(b))?(a):(b))
#endif

typedef struct CairoImageDev {
   CairoOutputDev* device;
   cairo_surface_t* surface;
   unsigned char* data;
} CairoImageDev;

static void my_poppler_cairo_prepare_dev(CairoImageDev* output_dev, Page* page,
                                         double scale, int rotation, int transparent)
{
   int width;
   int height;

   int rotate = (rotation + page->getRotate()) % 360;

   if (rotate == 90 || rotate == 270) 
   {
#ifdef POPPLER_0_4
      width = MAX((int)(page->getHeight() * scale + 0.5), 1);
      height = MAX((int)(page->getWidth() * scale + 0.5), 1);
#endif
#ifdef POPPLER_0_5
      width = MAX((int)(page->getMediaHeight() * scale + 0.5), 1);
      height = MAX((int)(page->getMediaWidth() * scale + 0.5), 1);
#endif
   }
   else
   {
#ifdef POPPLER_0_4
      width = MAX((int)(page->getWidth() * scale + 0.5), 1);
      height = MAX((int)(page->getHeight() * scale + 0.5), 1);
#endif
#ifdef POPPLER_0_5
      width = MAX((int)(page->getMediaWidth() * scale + 0.5), 1);
      height = MAX((int)(page->getMediaHeight() * scale + 0.5), 1);
#endif
   }

   int rowstride = width * 4;
   unsigned char* data = (unsigned char*)malloc(height * rowstride);
   memset(data, (transparent ? 0x00 : 0xff), height * rowstride);

   cairo_surface_t* surface = cairo_image_surface_create_for_data(data, CAIRO_FORMAT_ARGB32, width, height, rowstride);

   output_dev->device->setSurface(surface);
   output_dev->surface = surface;
   output_dev->data = data;
}

void* poppler_cairo_img_device_create(void)
{  
   BEGIN_SYNCHRONIZED;
      CairoOutputDev* cairoDevice = new CairoOutputDev();
      CairoImageDev* imageDevice = (CairoImageDev*)malloc(sizeof(CairoImageDev));
      imageDevice->device = cairoDevice;
      imageDevice->surface = NULL;
      imageDevice->data = NULL;
   END_SYNCHRONIZED;

   return imageDevice;
}

void poppler_cairo_img_device_start_doc(void* output_dev, void* poppler_document)
{
   if (!output_dev || !poppler_document)
   {
     return;
   }
    
   SYNCHRONIZED(CAIRO_DEV_IMG(output_dev)->device->startDoc(PDF_DOC(poppler_document)->getXRef()));
}

void poppler_cairo_img_device_destroy(void* output_dev)
{
   if (!output_dev)
   {
      return;
   }

   SYNCHRONIZED(delete CAIRO_DEV_IMG(output_dev)->device);
   free(CAIRO_DEV_IMG(output_dev));
}

int poppler_cairo_img_device_display_slice(void* output_dev, void* poppler_page,
                                           void* poppler_document,
                                           float hDPI, float vDPI, float baseDPI,
                                           int rotate,
                                           float sliceX, float sliceY,
                                           float sliceW, float sliceH)
{
   if (!output_dev || !poppler_page || !poppler_document)
   {
      return 0;
   }

   double scale = MAX(hDPI / baseDPI, vDPI / baseDPI);
   my_poppler_cairo_prepare_dev(CAIRO_DEV_IMG(output_dev), PAGE(poppler_page),
                                scale, rotate, 0); 
    
   SYNCHRONIZED(PAGE(poppler_page)->displaySlice(CAIRO_DEV_IMG(output_dev)->device,
                                                 (double)hDPI, (double)vDPI,
                                                 rotate,
#ifdef POPPLER_0_5
						 gTrue, // use MediaBox
#endif
                                                 gTrue, // Crop
                                                 (int)sliceX, (int)sliceY,
                                                 (int)sliceW, (int)sliceH,
                                                 NULL, // Links
                                                 PDF_DOC(poppler_document)->getCatalog()));
                                     
  return 1;
}

int poppler_cairo_img_device_get_data(void* output_dev, unsigned char** data,
                                      int* width, int* height, int* rowstride)
{
   if (!output_dev || !CAIRO_DEV_IMG(output_dev)->surface || !CAIRO_DEV_IMG(output_dev)->data)
   {
      return 0;
   }
   
   *data = CAIRO_DEV_IMG(output_dev)->data;
   *width = cairo_image_surface_get_width(CAIRO_DEV_IMG(output_dev)->surface);
   *height = cairo_image_surface_get_height(CAIRO_DEV_IMG(output_dev)->surface);
   *rowstride = (*width) * 4;

   cairo_surface_destroy(CAIRO_DEV_IMG(output_dev)->surface);
   CAIRO_DEV_IMG(output_dev)->surface = NULL;
   CAIRO_DEV_IMG(output_dev)->data = NULL; // freed after poppler_cairo_img_device_get_rgb
   
   return 1;
}

int poppler_cairo_img_device_get_rgb(unsigned char* cairo_data, unsigned char** rgb_data,
                                     int width, int height, int rowstride)
{
   if (!cairo_data)
   {
      return 0;
   }

   unsigned char* rgb_data_ptr = *rgb_data;
   for (int row = 0; row < height; row++)
   {
      unsigned int *src;
      src = (unsigned int *) (cairo_data + row * rowstride);
      for (int col = 0; col < width; col++)
      {
         *rgb_data_ptr++ = (*src >> 16) & 0xff;
         *rgb_data_ptr++ = (*src >> 8) & 0xff;
         *rgb_data_ptr++ = (*src >> 0) & 0xff;
         src++;
      }
   }

   free(cairo_data);

   return 1;
}

