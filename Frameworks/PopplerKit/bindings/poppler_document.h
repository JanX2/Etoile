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

#ifndef _H_POPPLER_DOCUMENT
#define _H_POPPLER_DOCUMENT

#ifdef __cplusplus 
extern "C" {
#endif

void* poppler_document_create_with_path(const char* path);
void poppler_document_destroy(void* poppler_document);
int poppler_document_is_ok(void* poppler_document);
int poppler_document_get_err_code(void *poppler_document);
unsigned poppler_document_count_pages(void* poppler_document);

#ifdef __cplusplus 
};
#endif

#endif
