#import "MainWindow.h"
#import "GNUstep.h"
#import "Global.h"

@implementation MainWindow

/* Toolbar delegate */
- (NSArray*) toolbarAllowedItemIdentifiers: (NSToolbar*)toolbar
{
  return [NSArray arrayWithObjects: 
                    RSSReaderSubscribeToolbarItemIdentifier,
                    RSSReaderRefreshAllToolbarItemIdentifier,
		    NSToolbarFlexibleSpaceItemIdentifier,
                    RSSReaderSearchToolbarItemIdentifier,
                                    nil];
}

- (NSArray*) toolbarDefaultItemIdentifiers: (NSToolbar*)toolbar
{
  return [self toolbarAllowedItemIdentifiers: toolbar];
}

- (NSArray*) toolbarSelectableItemIdentifiers: (NSToolbar*)toolbar
{
  return [self toolbarAllowedItemIdentifiers: toolbar];
}

- (NSToolbarItem*) toolbar: (NSToolbar *) toolbar
                   itemForItemIdentifier: (NSString *) iden
                   willBeInsertedIntoToolbar: (BOOL) flag
{
  NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier: iden];
  if ([iden isEqualToString: RSSReaderSubscribeToolbarItemIdentifier]) 
  {
    [item setLabel: @"Subscribe"];
    [item setAction: @selector(subscribe:)];
  } 
  else if ([iden isEqualToString: RSSReaderRefreshAllToolbarItemIdentifier]) 
  {
    [item setLabel: @"Refresh All"];
    [item setAction: @selector(reloadAll:)];
  } 
  else if ([iden isEqualToString: RSSReaderSearchToolbarItemIdentifier]) 
  {
    NSRect rect = NSMakeRect(0, 0, 200, 30);
    searchField = [[NSSearchField alloc] initWithFrame: rect];
    [searchField setAction: @selector(search:)];
    [[searchField cell] setSendsWholeSearchString: YES];

    [item setLabel: @"Search"];
    [item setView: searchField];
    [item setMinSize: [searchField frame].size];
    [item setMaxSize: [searchField frame].size];
  }
  return AUTORELEASE(item);
}

- (NSSearchField *) searchField
{
  return searchField;
}

@end
