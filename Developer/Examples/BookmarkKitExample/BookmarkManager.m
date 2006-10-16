#import "BookmarkManager.h"
#import "BookmarkManagerModel.h"
#import "BookmarkManagerView.h"
#import <BookmarkKit/BookmarkKit.h>
#import "GNUstep.h"

@implementation BookmarkManager


- (void) addBookmark: (id)sender
{
  [model addBookmark: sender];
}

- (void) removeBookmark: (id)sender
{
  [model removeBookmark: sender];
}

- (void) addGroup: (id)sender
{
  [model addGroup: sender];
}

- (void) removeGroup: (id)sender
{
  [model removeGroup: sender];
}

- (void) openBookmark: (id)sender
{
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  int result = [panel runModalForTypes: [NSArray arrayWithObject: @"bookmark"]];
  if (result == NSOKButton) {
    NSArray *urls = [panel URLs];
    if ([urls count] > 0) {
      ASSIGN(bookmarkStore, [BKBookmarkStore sharedBookmarkAtPath: [[urls objectAtIndex: 0] path]]);
      [model setBookmarkStore: bookmarkStore];
      [bookmarkManagerView reloadData];
    }
  }
}

- (void) saveBookmark: (id)sender
{
  if (bookmarkStore) {
    [bookmarkStore save];
  }
}

- (void) awakeFromNib
{
  [bookmarkManagerView reloadData];
  ASSIGN(model, [bookmarkManagerView model]);
}

- (void) applicationWillFinishLaunching: (NSNotification *) not
{
}

- (void) applicationDidFinishLaunching: (NSNotification *) not
{
}

- (void) dealloc
{
  DESTROY(model);
  [super dealloc];
}

@end
