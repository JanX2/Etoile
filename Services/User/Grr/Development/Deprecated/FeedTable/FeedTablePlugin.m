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

#import "FeedTablePlugin.h"

#import "NumberedImageTextCell.h"
#import "Article.h"
#import "Feed.h"


int compareFeedArticleCounts( id feedA, id feedB, void* context ) {
    id<Feed> a = feedA;
    id<Feed> b = feedB;
    
    int articleCountA = [a unreadArticleCount];
    int articleCountB = [b unreadArticleCount];
    
    if (articleCountA == articleCountB) {
        return NSOrderedSame;
    } else if ( articleCountA > articleCountB ) {
        return NSOrderedAscending;
    } else {
        return NSOrderedDescending;
    }
}

@implementation FeedTablePlugin

// Class methods



// Instance methods
-(void)awakeFromNib
{
    ASSIGN(table, [(NSScrollView*)_view documentView]);
    
    // Table columns
    ASSIGN(nameCol,  [table tableColumnWithIdentifier: @"feeds"]);
    
    // special cell for name col
    [nameCol setDataCell: [[NumberedImageTextCell alloc] init]];
    
    // Table autosaving
    [table setAutosaveName: @"Feed Table"];
    [table setAutosaveTableColumns: YES];
    
    // Get notifications whenever an article changes its read flag
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(articleReadFlagChanged:)
                                                 name: ArticleReadFlagChangedNotification
                                               object: nil];
}

/**
 * This method gets called whenever an article's read flag changes.
 */
-(void) articleReadFlagChanged: (NSNotification*) notification
{
    id<Feed> feed = [(id<Article>)[notification object] feed];
    
    NSAssert1(
        feed != nil,
        @"The article read flag change notification %@ was bad. (No feed ptr)",
        notification
    );
    
    if ([feeds containsObject: feed]) {
        [table reloadData];
    }
}

-(id)init
{
    if ((self = [super init]) != nil) {
        [_view retain];
    }
    
    return self;
}


/**
 * Sets a new array without sending a change notification. (It does
 * reload its own table view, though.)
 */
-(void) setNewArrayNotNotifying: (NSArray*) anArray
{
    if ([anArray isEqual: feeds]) {
        return;  // nothing to do
    }
    
    // Calculate new selected index. If nothing can be selected, index will be NSNotFound
    int index = [table selectedRow];
    if (index == -1) {
        index = NSNotFound;
    } else {
        id item = [feeds objectAtIndex: index];
        index = [anArray indexOfObject: item];
    }
    
    ASSIGN(feeds, anArray);
    ASSIGN(articleSelection, nil); // may need to be recalculated
    
    // Reload table
    [table reloadData];
    
    // ...and set the selected object.
    if (index == NSNotFound) {
       [table deselectAll: self];
    } else {
       [table selectRowIndexes: [NSIndexSet indexSetWithIndex: index]
          byExtendingSelection: NO];
    }
}

// --------------- Component piping ------------

-(void)componentDidUpdateSet: (NSNotification*) aNotification
{
    id<OutputProvidingComponent> outputComponent = [aNotification object];
    
    NSArray* newArticleArray =
        [[outputComponent objectsForPipeType: [PipeType articleType]] allObjects];
    
    ASSIGN(articles, newArticleArray);
    
    NSArray* newFeedsArray =
        [[[outputComponent objectsForPipeType: [PipeType feedType]] allObjects]
            sortedArrayUsingFunction: compareFeedArticleCounts context: nil];
    
    [self setNewArrayNotNotifying: newFeedsArray];
    
    [self notifyChanges];
}

-(NSSet*) objectsForPipeType: (id<PipeType>)aPipeType
{
    // If nothing is selected, just return nothing
    int index = [table selectedRow];
    if (index == -1) {
        return [NSSet new];
    }
    
    if (aPipeType == [PipeType articleType]) {
        // Articles: Return all articles in the selected feed
        //           using lazy set creation
        if (articleSelection == nil) {
            id<Feed> feed = [feeds objectAtIndex: index];
            
            ASSIGN(articleSelection, [feed articleSet]);
        }
        
        return articleSelection;
    } else if (aPipeType == [PipeType feedType]) {
        // Feeds: Return the set with the selected feed
        
        return [NSSet setWithObject: [feeds objectAtIndex: index]];
    }
    
    // In any other case, return the empty set
    return [NSSet new];
}

// ---------------- NSTableView data source ----------------------

- (int) numberOfRowsInTableView: (NSTableView *)aTableView
{
    return [feeds count];
}

- (id)           tableView: (NSTableView *)aTableView
 objectValueForTableColumn: (NSTableColumn *)aTableColumn
                       row: (int)rowIndex;
{
    id<Feed> feed = [feeds objectAtIndex: rowIndex];
    id result = nil;
    
    if (aTableColumn == nameCol) {
        result = [feed feedName];
    }
    
    return result;
}

// ------------------- NSTableView delegate ------------------------

- (void) tableViewSelectionDidChange: (NSNotification*) notif
{
    // clear article selection set
    ASSIGN(articleSelection, nil);
    
    [self notifyChanges];
}

-(void) tableView: (NSTableView*) aTableView
    willDisplayCell: (id)aCell
    forTableColumn: (NSTableColumn*) aTableColumn
    row: (int)rowIndex
{
    if (aTableColumn == nameCol) {
        NumberedImageTextCell* cell = aCell;
        
        id<Feed> feed = [feeds objectAtIndex: rowIndex];
        
        if ([feed isFetching]) {
            [cell setImage: [NSImage imageNamed: @"FeedFetching"]];
        } else {
            [cell setImage: [NSImage imageNamed: @"Feed"]];
        }
        
        if ([cell isKindOfClass: [NumberedImageTextCell class]]) {
            [cell setNumber: [feed unreadArticleCount]];
        }
    }
}

@end
