/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

/**
 * This must be implemented by any toolbar delegate.
 * Components may choose to implement this to provide toolbar items.
 */
@protocol ToolbarDelegate <NSObject>

- (NSToolbarItem*)toolbar: (NSToolbar*)toolbar
    itemForItemIdentifier: (NSString*)itemIdentifier
willBeInsertedIntoToolbar: (BOOL)flag;
// required method
- (NSArray*) toolbarAllowedItemIdentifiers: (NSToolbar*)toolbar;
// required method
- (NSArray*) toolbarDefaultItemIdentifiers: (NSToolbar*)toolbar;

@end
