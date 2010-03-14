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
#include "poppler_page.h"
#include <PDFDoc.h>
#include <Catalog.h>
#include <Page.h>

#define PDF_DOC(obj) static_cast<PDFDoc*>(obj)
#define PAGE(obj) static_cast<Page*>(obj)

void* poppler_page_create(void* poppler_document, unsigned pageIndex)
{
   if (!poppler_document)
   {
      return NULL;
   }
   
   if ((pageIndex <= 0) || 
       ((int)pageIndex > PDF_DOC(poppler_document)->getNumPages()))
   {
      return NULL;
   }
   
   Catalog* catalog = PDF_DOC(poppler_document)->getCatalog();
   Page* page = catalog->getPage(pageIndex);
   return page;
}

void poppler_page_destroy(void* poppler_page)
{
   // nothing to do here so far, page is maintained by
   // a document's catalog
}

int poppler_page_get_rotate(void* poppler_page)
{
   if (!poppler_page)
   {
      return -1;
   }
   
   return PAGE(poppler_page)->getRotate();
}

double poppler_page_get_width(void* poppler_page)
{
   if (!poppler_page)
   {
      return -1;
   }
   
   return PAGE(poppler_page)->getMediaWidth();
}

double poppler_page_get_height(void* poppler_page)
{
   if (!poppler_page)
   {
      return -1;
   }
   
   return PAGE(poppler_page)->getMediaHeight();
}
