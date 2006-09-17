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
 #import <AppKit/AppKit.h>
 #import "PDFContentView.h"
 #import "Document.h"
 
// Main Menu Tags
typedef enum {
   MainMenuTagApplication = 1,
   MainMenuTagFile = 2,
   MainMenuTagEdit = 3,
   MainMenuTagGoto = 4,
   MainMenuTagView = 5,
   MainMenuTagWindow = 6,
   MainMenuTagHelp = 7
} MainMenuTags;

// View Menu Tags
typedef enum {
   ViewMenuTagActualSize = 1,
   ViewMenuTagZoomIn = 2,
   ViewMenuTagZoomOut = 3,
   ViewMenuTagShowAll = 4,
   ViewMenuTagFitWidth = 5,
   ViewMenuTagFitHeight = 6,
   ViewMenuTagFitPage = 7
} ViewMenuTags;

/**
 * Keeps track of the application's main menu state.
 */
@interface MenuState : NSObject
{
   id<PDFContentView>  contentView;
   Document*           document;
}

- (id) initWithDocument: (Document*)aDocument
            contentView: (id<PDFContentView>)aContentView;
            
- (void) stateChanged;

@end
