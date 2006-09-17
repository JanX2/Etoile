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

#import <Foundation/Foundation.h>

@class PopplerDocument;

typedef enum
{
   POPPLER_PAGE_ORIENTATION_PORTRAIT,
   POPPLER_PAGE_ORIENTATION_LANDSCAPE,
   POPPLER_PAGE_ORIENTATION_UPSIDEDOWN,
   POPPLER_PAGE_ORIENTATION_SEASCAPE,
   POPPLER_PAGE_ORIENTATION_UNSET
} PopplerPageOrientation;

/**
 * I represent a page of a PDF document. You can access my content and
 * other properties. Send the page message to some PopplerDocument in
 * order to obtain an instance of me.
 */
@interface PopplerPage : NSObject
{
   void*             poppler_page;
   PopplerDocument*  document;
   unsigned          index;
}

- (id) initWithDocument: (PopplerDocument*)aDocument index: (unsigned)anIndex;

- (unsigned) index;
- (NSSize) size;
- (PopplerPageOrientation) orientation;
- (int) rotate;

- (NSArray*) findText: (NSString*)aTextString;

- (PopplerDocument*) document;

@end
