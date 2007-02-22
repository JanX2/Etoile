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

#import "PreferencesPanel.h"
#import "NSBundle+Extensions.h"

@implementation PreferencesPanel

// ---------------------------------
//    init and dealloc
// ---------------------------------

-(id) init
{
    if ((self = [super init]) != nil) {
        RETAIN(window);
        RETAIN(replacableView);
        
        ASSIGN(prefComponents, [NSMutableArray new]);
        ASSIGN(toolbarItemIdentifiers, [NSMutableArray new]);
        ASSIGN(toolbarItems, [NSMutableDictionary new]);
        
        // Set up preferences
        [self addPreferencesComponent: [NSBundle instanceForBundleWithName: @"Proxy"]];
        [self addPreferencesComponent: [NSBundle instanceForBundleWithName: @"URLOpening"]];
        [self addPreferencesComponent: [NSBundle instanceForBundleWithName: @"Fonts"]];
        
        NSToolbar* toolbar = AUTORELEASE(
            [(NSToolbar*)[NSToolbar alloc] initWithIdentifier: @"pref panel toolbar"]
        );
        [toolbar setDelegate: self];
        [toolbar setAllowsUserCustomization: NO];
        
        [window setToolbar: toolbar];
        [window setFloatingPanel: YES];
    }
    
    return self;
}

-(void) dealloc
{
    DESTROY(window);
    DESTROY(replacableView);
    
    DESTROY(prefComponents);
    DESTROY(toolbarItemIdentifiers);
    DESTROY(toolbarItems);
    [super dealloc];
}

// ---------------------------------
//    singleton
// ---------------------------------

+(PreferencesPanel*) shared
{
    static PreferencesPanel* singleton = nil;
    
    if (singleton == nil) {
        ASSIGN(singleton, [PreferencesPanel new]);
    }
    
    return singleton;
}


// ---------------------------------
//    adding new panels to the preference panel
// ---------------------------------

-(BOOL) addPreferencesComponent: (id<PreferencesComponent>) aPrefComponent
{
    NSAssert(
        [prefComponents count] == [toolbarItemIdentifiers count],
        @"Internal inconsistency: Number of toolbar items != number of pref panes."
    );
    
    [prefComponents addObject: aPrefComponent];
    
    NSToolbarItem* item =
        [[NSToolbarItem alloc] initWithItemIdentifier: [aPrefComponent prefPaneName]];
    [item setLabel: [aPrefComponent prefPaneName]];
    [item setImage: [aPrefComponent prefPaneIcon]];
    [item setAction: @selector(changeViewAction:)];
    [item setTarget: self];
    
    [toolbarItemIdentifiers addObject: [item itemIdentifier]];
    [toolbarItems setObject: item forKey: [item itemIdentifier]];
    
    return YES;
}


// ---------------------------------
//    NSToolbar delegate
// ---------------------------------

- (NSToolbarItem*)toolbar: (NSToolbar*)toolbar
    itemForItemIdentifier: (NSString*)itemIdentifier
willBeInsertedIntoToolbar: (BOOL)flag
{
    return [toolbarItems objectForKey: itemIdentifier];
}

// required method
- (NSArray*) toolbarAllowedItemIdentifiers: (NSToolbar*)toolbar
{
    return toolbarItemIdentifiers;
}

// required method
- (NSArray*) toolbarDefaultItemIdentifiers: (NSToolbar*)toolbar
{
    return toolbarItemIdentifiers;
}

// makes it a completely "selectable" toolbar
- (NSArray*) toolbarSelectableItemIdentifiers: (NSToolbar*)toolbar
{
    return toolbarItemIdentifiers;
}

// ---------------------------------
//    window open & close
// ---------------------------------

-(void) open
{
    [window makeKeyAndOrderFront: self];
}

-(void) close
{
    [window close];
}

// ---------------------------------
//    executed when a toolbar item is clicked
// ---------------------------------

-(void) changeViewAction: (NSToolbarItem*)sender
{
    id<ViewProvidingComponent, NSObject> comp;
    
    comp = [prefComponents objectAtIndex: 
        [toolbarItemIdentifiers indexOfObject: [sender itemIdentifier]]];
    
    NSAssert1(
        [comp conformsToProtocol: @protocol(ViewProvidingComponent)],
        @"Component %@ should be a view providing component!", comp
    );
    
    NSView* newView = [comp view];
    [newView setFrame: [replacableView frame]];
    [[replacableView superview] replaceSubview: replacableView with: newView];
    
    ASSIGN(replacableView, newView);
}

@end

