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
#import "SinglePageView.h"
#import "DocumentTools.h"
#import "MenuState.h"
#import "SearchController.h"

/**
 * Controller for Document windows.
 */
@interface Controller : NSWindowController
{
   IBOutlet NSScrollView*     scrollView;
   IBOutlet SearchController* searchController;

   SinglePageView* singlePageView;
   DocumentTools*  tools;
   MenuState*      menuState;

   BOOL windowIsVisible;
}

- (SearchController*) searchController;

/* Navigation */
- (IBAction) nextPage: (id)aSender;
- (IBAction) previousPage: (id)aSender;
- (IBAction) firstPage: (id)aSender;
- (IBAction) lastPage: (id)aSender;
- (IBAction) takePageFrom: (id)aSender;
- (IBAction) enterPageNumber: (id)aSender;

/* Zoom */
- (IBAction) takeZoomFrom: (id)aSender;
- (IBAction) zoomIn: (id)aSender;
- (IBAction) zoomOut: (id)aSender;
- (IBAction) zoomActualSize: (id)aSender;
- (IBAction) zoomToFit: (id)aSender;

/* Page Resizing */
- (IBAction) toggleFitWidth: (id)aSender;
- (IBAction) toggleFitHeight: (id)aSender;
- (IBAction) toggleFitPage: (id)aSender;

/* Scrolling */
- (IBAction) scrollPageUp: (id)aSender;
- (IBAction) scrollPageDown: (id)aSender;
- (IBAction) scrollLineUp: (id)aSender;
- (IBAction) scrollLineDown: (id)aSender;
- (IBAction) scrollToTop: (id)aSender;
- (IBAction) scrollToBottom: (id)aSender;
- (IBAction) scrollLineLeft: (id)aSender;
- (IBAction) scrollLineRight: (id)aSender;
- (IBAction) scrollToLeftEdge: (id)aSender;
- (IBAction) scrollToRightEdge: (id)aSender;

/* Find */
- (IBAction) findText: (id)aSender;

/* Content View */
- (IBAction) goSinglePage: (id)aSender;

/* Close */
- (IBAction) close: (id)aSender;

/* Abort the current (long-running) action */
- (IBAction) abortCurrentAction: (id)aSender;

@end
