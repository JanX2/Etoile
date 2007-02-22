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

#import <RSSKit/RSSArticleProtocol.h>

#import "ArticleOperations.h"
#import "Article.h"

#define BROWSE_IDENTIFIER @"Article.Ops.Browse"

@implementation ArticleOperationsComponent


-(id)init
{
    if ((self = [super init]) != nil) {
        // Article browsing toolbar item
        browseItem = [[NSToolbarItem alloc] initWithItemIdentifier: BROWSE_IDENTIFIER];
        [browseItem setLabel: _(@"View in WWW")];
        [browseItem setImage: [NSImage imageNamed: @"ArticleLink"]];
        [browseItem setAction: @selector(browseSelectedArticles)];
        [browseItem setTarget: self];
        
        // Article browsing menu item
        browseMenuItem = [[NSMenuItem alloc] initWithTitle: _(@"View in WWW")
                                                    action: @selector(browseSelectedArticles)
                                             keyEquivalent: @"b"];
        [browseMenuItem setTarget: self];
        
        #ifdef GRRRDEBUG
        debugItem = [[NSToolbarItem alloc] initWithItemIdentifier: @"Grr Debug Article"];
        [debugItem setLabel: @"Debug article"];
        [debugItem setImage: [NSImage imageNamed: @"PlainArticle"]];
        [debugItem setAction: @selector(debugSelectedArticles)];
        [debugItem setTarget: self];
        #endif
        
        // Provided identifiers
        NSArray* identifiers = [NSArray arrayWithObjects:
            BROWSE_IDENTIFIER,
            #ifdef GRRRDEBUG
            @"Grr Debug Article",
            #endif
            nil
        ];
        ASSIGN(allowedIdentifiers, identifiers);
        ASSIGN(defaultIdentifiers, allowedIdentifiers);
        
        // Init selected articles with empty set
        ASSIGN(selectedArticles, [NSSet new]);
        
        // Putting together the article menu
        NSMenu* menu = [[[NSMenu alloc] init] autorelease];
        [menu addItem: browseMenuItem];
        [[NSApp mainMenu] setSubmenu: menu forItem:
            [[NSApp mainMenu] itemWithTitle:
                NSLocalizedString(@"Article",
                    @"This translates to the name of the 'Article' main menu entry in the "
                    @"main Nib file. If you get it wrong, the menu will not be filled correctly.")]];
    }
    
    return self;
}

// input accepting component protocol

-(void)componentDidUpdateSet: (NSNotification*) aNotification
{
    id<OutputProvidingComponent> component = [aNotification object];
    
    ASSIGN(selectedArticles, [component objectsForPipeType: [PipeType articleType]]);
    
    BOOL isEnabled = ([selectedArticles count] > 0) ? YES : NO;
    [browseItem setEnabled: isEnabled];
    
    #ifdef GRRRDEBUG
    [debugItem setEnabled: isEnabled];
    #endif
}



// toolbar delegate protocol

- (NSToolbarItem*)toolbar: (NSToolbar*)toolbar
    itemForItemIdentifier: (NSString*)itemIdentifier
willBeInsertedIntoToolbar: (BOOL)flag
{
    if ([itemIdentifier isEqualToString: BROWSE_IDENTIFIER]) {
        return browseItem;
    }
    #ifdef GRRRDEBUG
    else if ([itemIdentifier isEqualToString: @"Grr Debug Article"]) {
        return debugItem;
    }
    #endif
    
    return nil; // this identifier was not found here
}

- (NSArray*) toolbarAllowedItemIdentifiers: (NSToolbar*)toolbar
{
    return allowedIdentifiers;
}

- (NSArray*) toolbarDefaultItemIdentifiers: (NSToolbar*)toolbar
{
    return defaultIdentifiers;
}


// own methods

-(void)browseSelectedArticles
{
    NSEnumerator* enumerator = [selectedArticles objectEnumerator];
    id<RSSArticle> article;
    
    while ((article = [enumerator nextObject]) != nil) {
        NSLog(@"FIXME: Browse article %@ here! :-)", [article headline]);
    }
}

#ifdef GRRRDEBUG
-(void)debugSelectedArticles
{
    NSEnumerator* enumerator = [selectedArticles objectEnumerator];
    id<Article> article;
    
    while ((article = [enumerator nextObject]) != nil) {
        NSLog(@"Article %@ is \n%@", [article headline], [article plistDictionary]);
        NSLog(@"Storage reseult: %d", [article store]);
    }
}
#endif

@end
