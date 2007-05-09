/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.
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
