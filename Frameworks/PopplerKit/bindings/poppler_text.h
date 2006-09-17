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

#ifndef _H_POPPLER_TEXT
#define _H_POPPLER_TEXT

#ifdef __cplusplus 
extern "C" {
#endif
   
void* poppler_text_device_create(int use_phys_layout, int use_raw_text_order, int append);
void poppler_text_device_destroy(void* text_device);
int poppler_text_display_page(void* text_device, void* poppler_page, void* poppler_document,
                              float hDPI, float vDPI, int rotate, int crop);
int poppler_text_find(void* text_device, unsigned int* text_utf32, unsigned text_len,
                      int start_at_top, int stop_at_bottom,
                      int start_at_last, int stop_at_last,
                      double* x_min, double* y_min, double* x_max, double* y_max);
   
#ifdef __cplusplus 
};
#endif

#endif

