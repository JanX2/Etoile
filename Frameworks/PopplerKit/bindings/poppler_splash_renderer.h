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

#ifndef _H_POPPLER_SPLASH_RENDERER
#define _H_POPPLER_SPLASH_RENDERER

#ifdef __cplusplus 
extern "C" {
#endif

void* poppler_splash_device_create(int bg_red, int bg_green, int bg_blue);
void poppler_splash_device_start_doc(void* output_dev, void* poppler_document);
void poppler_splash_device_destroy(void* output_dev);
int poppler_splash_device_display_slice(void* output_dev, void* poppler_page,
                                        void* poppler_document,
                                        float hDPI, float vDPI, int rotate,
                                        float sliceX, float sliceY,
                                        float sliceW, float sliceH);
int poppler_splash_device_get_bitmap(void* output_dev, void** bitmap,
                                     int* width, int* height);
int poppler_splash_device_get_rgb(void* bitmap, unsigned char** data);

#ifdef __cplusplus 
};
#endif

#endif
