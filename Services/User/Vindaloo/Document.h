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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <PopplerKit/PopplerKit.h>
#import "ZoomFactor.h"
#import "DocumentSelection.h"

extern NSString* kDocumentPageChangedNotification;
extern NSString* kDocumentSelectionChangedNotification;
extern NSString* kUserInfoKeyPageRect;


/**
 * A Vindaloo PDF Document.
 */
@interface Document : NSDocument
{
   PopplerDocument*           pdfdoc;
   PopplerPage*               page;
   id<PopplerDirectRenderer>  renderer;
   NSMutableDictionary*       selections;
}

- (PopplerDocument*) pdfDocument;

- (int) countPages;

- (void) setPageByIndex: (int)aPageIndex;
- (void) setPageByIndex: (int)aPageIndex requestVisibleRect: (NSRect)aRect;
- (int) pageIndex;
- (PopplerPage*) page;

- (BOOL) nextPage;
- (BOOL) previousPage;

- (NSSize) pageSize;

- (void) addSelection: (DocumentSelection*)selection;
- (void) clearSelections;
- (void) jumpToSelection: (DocumentSelection*)selection;

- (PopplerTextSearch*) newSearch;

- (void) drawPageAtPoint: (NSPoint)aPoint zoom: (ZoomFactor*)zoom;

@end

