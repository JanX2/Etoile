/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.
*/

#import "AppController.h"
#import <AppKit/AppKit.h>
#import "Components.h"
#import "Database.h"
#import "ToolbarDelegate.h"
#import "ArticleFactory.h"
#import "PreferencesPanel.h"
#import "NSBundle+Extensions.h"

@implementation AppController (Private)

/**
 * Loads a view providing component into the place of an existing view object.
 * Please not that the overriddenView parameter is _a_pointer_ to the reference
 * to the overridden view! The new view will also be retained!
 */
-(void)loadViewProvidingComponent: (id<ViewProvidingComponent>) aComponent overriddenView: (NSView**) overriddenView
{
    id<ViewProvidingComponent, NSObject> component = (id<NSObject>) aComponent;
    
    NSAssert1(
        [component conformsToProtocol: @protocol(ViewProvidingComponent)],
        @"Grr component %@ provides no view. So it cannot be used as such.", component
    );
    
    NSDebugLog(@"Module %@ is being loaded.", component);
    NSView* newView = [component view];
    
    NSAssert1(newView != nil, @"Component %@ had no view, although it should.", component);
    
    [newView setFrame: [*overriddenView frame]];
    [[*overriddenView superview] replaceSubview: *overriddenView with: newView];
    
    ASSIGN(*overriddenView, newView);
}

/**
 * Loads a component that acts as a toolbar delegate.
 * Returns YES on success, NO on failure.
 */
-(BOOL) loadToolbarProvidingComponent: (id<ToolbarDelegate>) aComponent
{
    if ([aComponent conformsToProtocol: @protocol(ToolbarDelegate)] == NO) {
        return NO;
    }
    
    [toolbarProviders addObject: aComponent];
    return YES;
}

/*
 * Helper method that sends a message with the given selector to each
 * registered toolbar provider and concatenates the results of these
 * method calls. The methods belonging to the selector must return
 * a result of the NSArray* type.
 * 
 * If the implementation of the method is optional for the toolbar
 * provider, the optionalMethod flag can be set to YES to let this
 * method check if the method is implemented by the toolbar providers
 * before sending the message to them.
 */
- (NSArray*) askToolbarProvidersForArrayUsingSelector: (SEL) aSelector
                                              toolbar: (NSToolbar*) toolbar
                                       optionalMethod: (BOOL) optionalMethod
{
    NSMutableArray* mutArray = [NSMutableArray new];
    
    int i;
    for (i=0; i<[toolbarProviders count]; i++) {
        id<ToolbarDelegate> provider = [toolbarProviders objectAtIndex: i];
        BOOL executionPossible = NO;
        
        if (optionalMethod == NO) {
            executionPossible = YES;
        } else {
            if ([provider respondsToSelector: aSelector]) {
                executionPossible = YES;
            }
        }
        
        if (executionPossible == YES) {
            [mutArray addObjectsFromArray: [provider performSelector: aSelector
                                                     withObject: toolbar]];
        }
    }
    
    return [NSArray arrayWithArray: mutArray];
}


@end

@implementation AppController

-(void) awakeFromNib
{
    // Retain some views
    [articleSetView retain];
    [articleView retain];
    [databaseView retain];
    
    // toolbar is created in applicationDidFinishLaunching
    
    // Make sure the toolbar provider array is initialized
    ASSIGN(toolbarProviders, [NSMutableArray new]);
}


// ------------------------------------------------
//    Application notifications
// ------------------------------------------------

// Macros for setting font names and sizes in defaults without overwriting
// existing values

// obj is a NSFont object, key is a NSString
#define SET_FAMILY( obj, key )       \
    if ([defaults objectForKey: (key)] == nil) {     \
        [defaults setObject: [(obj) fontName] forKey: (key)];   \
    }

// obj is a float, key is a NSString
#define SET_SIZE( obj, key )       \
    if ([defaults objectForKey: (key)] == nil) {     \
        [defaults setObject: [NSNumber numberWithFloat: (obj)] forKey: (key)];   \
    }


-(void) applicationDidFinishLaunching: (NSNotification*) aNotification
{
    // First create a different RSSFactory and replace the current one with that.
    [RSSFactory setFactory: [ArticleFactory new]];
    
    // Make sure the fonts are set.
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    SET_FAMILY( [NSFont systemFontOfSize: [NSFont systemFontSize]], @"RSSReaderFeedListFontDefaults" );
    SET_SIZE( [NSFont systemFontSize], @"RSSReaderFeedListSizeDefaults" );
    SET_FAMILY( [NSFont systemFontOfSize: [NSFont systemFontSize]], @"RSSReaderArticleListFontDefaults" );
    SET_SIZE( [NSFont systemFontSize], @"RSSReaderArticleListSizeDefaults" );
    SET_FAMILY( [NSFont userFontOfSize: [NSFont systemFontSize]], @"RSSReaderArticleContentFontDefaults" );
    SET_SIZE( [NSFont systemFontSize], @"RSSReaderArticleContentSizeDefaults" );
    SET_FAMILY( [NSFont userFixedPitchFontOfSize: [NSFont systemFontSize]], @"RSSReaderFixedArticleContentFontDefaults" );
    SET_SIZE( [NSFont systemFontSize], @"RSSReaderFixedArticleContentSizeDefaults" );
    
    
    // Create different Grr components
    id<OutputProvidingComponent> db = [Database shared];
    id<ViewProvidingComponent,FilterComponent> plugin1 = [NSBundle instanceForBundleWithName: @"ArticleTable"];
    id<ViewProvidingComponent,FilterComponent> plugin2 = [NSBundle instanceForBundleWithName: @"ArticleView"];
    id<ViewProvidingComponent,FilterComponent> feedPlugin = [NSBundle instanceForBundleWithName: @"DatabaseTreeView"];
    id<ToolbarDelegate> articleOpsToolbar = [NSBundle instanceForBundleWithName: @"ArticleOperations"];
    id<ToolbarDelegate> feedOpsToolbar = [NSBundle instanceForBundleWithName: @"DatabaseOperations"];
    id<ToolbarDelegate,FilterComponent> searchingComponent = [NSBundle instanceForBundleWithName: @"Searching"];
    
    NSAssert(plugin1 != nil, @"Article Table plugin could not be loaded.");
    NSAssert(plugin2 != nil, @"Article View plugin could not be loaded.");
    NSAssert(feedPlugin != nil, @"Feed Table plugin could not be loaded.");
    
    // Connect the created components...
    NSNotificationCenter* defaultCenter = [NSNotificationCenter defaultCenter];
    
    [defaultCenter addObserver: searchingComponent
        selector: @selector(componentDidUpdateSet:)
        name: ComponentDidUpdateNotification
        object: feedPlugin];
    
    [defaultCenter addObserver: plugin1
        selector: @selector(componentDidUpdateSet:)
        name: ComponentDidUpdateNotification
        object: searchingComponent];
    
    [defaultCenter addObserver: plugin2
        selector: @selector(componentDidUpdateSet:)
        name: ComponentDidUpdateNotification
        object: plugin1];
    
    [defaultCenter addObserver: articleOpsToolbar
        selector: @selector(componentDidUpdateSet:)
        name: ComponentDidUpdateNotification
        object: plugin1];
    
    [defaultCenter addObserver: feedOpsToolbar
        selector: @selector(componentDidUpdateSet:)
        name: ComponentDidUpdateNotification
        object: feedPlugin];
    
    // Insert the created viewable components into the GUI
    [self loadViewProvidingComponent: plugin1 overriddenView: &articleSetView];
    [self loadViewProvidingComponent: plugin2 overriddenView: &articleView];
    [self loadViewProvidingComponent: feedPlugin overriddenView: &databaseView];
    
    [self loadToolbarProvidingComponent: feedOpsToolbar];
    [self loadToolbarProvidingComponent: articleOpsToolbar];
    [self loadToolbarProvidingComponent: searchingComponent];
    
    [defaultCenter postNotificationName: ComponentDidUpdateNotification object: db];
    
    // Create toolbar
    fToolbar = [(NSToolbar*)[NSToolbar alloc] initWithIdentifier: @"main window toolbar"];
    [fToolbar setDelegate: self];
    
    [window setToolbar: fToolbar];

    // Set the autosave name for the window to let the window
    // appear in the same place next time, too. :)
    [window setFrameAutosaveName: @"Grr main window"];
    
    // Now that everything is loaded, we can show the window.
    [window makeKeyAndOrderFront: self];
    
    // Application startup is finished. See applicationDidBecomeActive: below.
    applicationStartupFinished = YES;
}

- (void) applicationDidBecomeActive: (NSNotification*) aNotification
{
    // Only order front if application startup is finished. If we didn't do this,
    // the window would instantly be shown, as this method is called before it
    // is supposed to be shown. (That is, when all the plugin bundles are loaded.)
    if (applicationStartupFinished) {
        [window makeKeyAndOrderFront: self];
    }
}

- (NSApplicationTerminateReply) applicationShouldTerminate: (NSApplication*) application
{
    if ([[Database shared] archive] == NO) {
        NSLog(@"Database could not be saved to disk"); // FIXME: better error handling needed!
    }
    
    // toolbar must be removed before terminating, so that the window
    // can still store its *real* location, not the location the GNUstep
    // impl of NSToolbar messed up.
    [fToolbar setVisible: NO];
    return NSTerminateNow;
}

// ------------------------------------------------
//    Opening files
// ------------------------------------------------

- (BOOL) application: (NSApplication *) application
            openFile: (NSString *) fileName
{
    NSURL* URL = [NSURL fileURLWithPath: fileName];
    
    if (URL == nil) {
        return NO;
    }
    
    return [[Database shared] subscribeToURL: URL];
}


// ------------------------------------------------
//    Handlers for actions
// ------------------------------------------------

-(void) openPreferencesPanel: (id)sender
{
    [[PreferencesPanel shared] open];
}

// ------------------------------------------------
//    Toolbar delegate
// ------------------------------------------------

// required method
- (NSToolbarItem*)toolbar: (NSToolbar*)toolbar
    itemForItemIdentifier: (NSString*)itemIdentifier
willBeInsertedIntoToolbar: (BOOL)flag
{
    NSToolbarItem* result = nil;
    
    int i;
    for (i=0; i<[toolbarProviders count] && result == nil; i++) {
        id<ToolbarDelegate> provider = [toolbarProviders objectAtIndex: i];
        
        result = [provider toolbar: toolbar
                    itemForItemIdentifier: itemIdentifier
                    willBeInsertedIntoToolbar: flag];
    }
    
    return result;
}

// required method
- (NSArray*) toolbarAllowedItemIdentifiers: (NSToolbar*)toolbar
{
    return [self askToolbarProvidersForArrayUsingSelector: _cmd
                                                  toolbar: toolbar
                                           optionalMethod: YES];
}

// required method
- (NSArray*) toolbarDefaultItemIdentifiers: (NSToolbar*)toolbar;
{
    return [self askToolbarProvidersForArrayUsingSelector: _cmd
                                                  toolbar: toolbar
                                           optionalMethod: YES];
}

// optional method
- (NSArray*) toolbarSelectableItemIdentifiers: (NSToolbar *)toolbar;
{
    return [self askToolbarProvidersForArrayUsingSelector: _cmd
                                                  toolbar: toolbar
                                           optionalMethod: YES];
}

@end
