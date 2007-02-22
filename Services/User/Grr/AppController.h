/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>
   
   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License version 2 as published by the Free Software Foundation.
   
   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import <AppKit/AppKit.h>

@interface AppController : NSObject
{
    IBOutlet NSView* articleView;
    IBOutlet NSView* articleSetView;
    IBOutlet NSView* databaseView;
    
    IBOutlet NSWindow* window;
    NSToolbar* fToolbar;
    
    NSMutableArray* toolbarProviders;
    
    BOOL applicationStartupFinished;
}

// Toolbar delegate

// required method
- (NSToolbarItem*)toolbar: (NSToolbar*)toolbar
    itemForItemIdentifier: (NSString*)itemIdentifier
willBeInsertedIntoToolbar: (BOOL)flag;
// required method
- (NSArray*) toolbarAllowedItemIdentifiers: (NSToolbar*)toolbar;
// required method
- (NSArray*) toolbarDefaultItemIdentifiers: (NSToolbar*)toolbar;
// optional method
- (NSArray *) toolbarSelectableItemIdentifiers: (NSToolbar *)toolbar;

@end

@interface AppController (Private)
@end
