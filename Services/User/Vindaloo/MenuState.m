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

#import "MenuState.h"

/**
 * Non-Public methods.
 */
@interface MenuState (Private)
- (void) myUpdateResizePolicy;
@end


@implementation MenuState

- (id) initWithDocument: (Document*)aDocument
            contentView: (id<PDFContentView>)aContentView
{
   NSAssert(aDocument, @"nil document");
   NSAssert(aContentView, @"nil content view");

   self = [super init];
   if (self)
   {
      document = aDocument;
      contentView = aContentView;
      [self stateChanged];
   }
   
   return self;
}

- (void) stateChanged
{
   [self myUpdateResizePolicy];
}

@end


/* ----------------------------------------------------- */
/*  Category Private                                     */
/* ----------------------------------------------------- */

@implementation MenuState (Private)

- (void) myUpdateResizePolicy
{
   NSMenuItem* viewMenu = (id)[[NSApp mainMenu] itemWithTag: MainMenuTagView];
   if (!viewMenu)
   {
      NSLog(@"WARNING: view menu not found!");
      return;
   }
   
   ResizePolicy policy = [contentView resizePolicy];
   
   NSMenuItem* fitWidthItem = (id)[[viewMenu submenu] itemWithTag: ViewMenuTagFitWidth];
   [fitWidthItem setState: (policy == ResizePolicyFitWidth ? NSOnState : NSOffState)];
   
   NSMenuItem* fitHeightItem = (id)[[viewMenu  submenu] itemWithTag: ViewMenuTagFitHeight];
   [fitHeightItem setState: (policy == ResizePolicyFitHeight ? NSOnState: NSOffState)];
   
   NSMenuItem* fitPageItem = (id)[[viewMenu  submenu] itemWithTag: ViewMenuTagFitPage];
   [fitPageItem setState: (policy == ResizePolicyFitPage ? NSOnState : NSOffState)];
}

@end
