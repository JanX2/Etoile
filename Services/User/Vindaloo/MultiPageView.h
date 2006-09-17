/*
 * Copyright (C) 2005  Stefan Kleine Stegemann
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

#import <PDFKit/PDFDocument.h>
#import <Foundation/NSArray.h>
#import <AppKit/NSView.h>
#import <AppKit/NSColor.h>

/**
 * A view which displays multiple pages of a PDF document,
 * side by side in a raster.
 */
@interface MultiPageView : NSView
{
   PDFDocument*    pdfdoc;
   NSMutableArray* pages;
   unsigned        scaleFactor;
   float           vspace;
   float           hspace;
   NSColor*        background;
}

- (id) initWithFrame: (NSRect)aFrame
         scaleFactor: (unsigned)aScaleFactor;

- (void) setDocument: (PDFDocument*)aDocument;
- (PDFDocument*) document;

- (void) setScaleFactor: (unsigned)aScaleFactor;
- (unsigned) scaleFactor;

- (void) setVerticalSpace: (float)aSpace;
- (float) verticalSpace;

- (void) setHorizontalSpace: (float)aSpace;
- (float) horizontalSpace;

- (void) setBackground: (NSColor*)aColor;
- (NSColor*) background;

@end
