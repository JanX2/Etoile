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
#include "poppler_document.h"
#include <PDFDoc.h>
#include <goo/GooString.h>

#define PDF_DOC(obj) static_cast<PDFDoc*>(obj)

void* poppler_document_create_with_path(const char* path)
{
   if (!path)
   {
      return NULL;
   }
   
   GooString* path_g = new GooString(path);
   PDFDoc* doc = new PDFDoc(path_g, NULL, NULL);
   return doc;
}

void poppler_document_destroy(void* poppler_document)
{
   fprintf(stderr, "poppler_document_destroy\n"); fflush(stderr);

   if (!poppler_document)
   {
      return;
   }
   
   delete PDF_DOC(poppler_document);
}

int poppler_document_is_ok(void* poppler_document)
{
   if (!poppler_document)
   {
      return 0;
   }

   return PDF_DOC(poppler_document)->isOk();   
}

int poppler_document_get_err_code(void *poppler_document)
{
   if (!poppler_document)
   {
      return -1;
   }
   
   return PDF_DOC(poppler_document)->getErrorCode();
}

unsigned poppler_document_count_pages(void* poppler_document)
{
   if (!poppler_document)
   {
      return 0;
   }
   
   return PDF_DOC(poppler_document)->getNumPages();
}
