#import "PreferencePane.h"
#import "Global.h"

@implementation PreferencePane

- (void) removeDateAction: (id) sender
{
  int number = [[sender selectedItem] tag];
  [[NSUserDefaults standardUserDefaults] 
                   setInteger: number
                       forKey: RSSReaderRemoveArticlesAfterDefaults];
  NSString *s = [NSString stringWithFormat: @"Remove article older than %d days", number];
  [[NSNotificationCenter defaultCenter]
               postNotificationName: RSSReaderLogNotification
               object: s];
}

- (id) init 
{
  self = [super init];

  if ([NSBundle loadNibNamed: @"PreferencePane" owner: self] == NO) {
    [self dealloc];
    return nil;
  }

  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
         @"01General", @"identifier",
         @"General", @"name",
         @"01General", @"path",
         [NSValue valueWithPointer: [self class]], @"class",
         self, @"instance", nil];
  [[PKPreferencePaneRegistry sharedRegistry] addPlugin: dict];
  
  return self;
}

- (void) dealloc
{
  [super dealloc];
}

- (void) willSelect
{
  int number = [[NSUserDefaults standardUserDefaults] integerForKey: RSSReaderRemoveArticlesAfterDefaults];
  /* Find the item with the right tag */
  BOOL found = NO;
  int i, count = [removeDateButton numberOfItems];
  for (i = 0; i < count; i++) {
    id <NSMenuItem> item = [removeDateButton itemAtIndex: i];
    if ([item tag] == number) {
      [removeDateButton selectItem: item];
      found = YES;
      break;
    }
  }
  if (found == NO) {
    [[NSNotificationCenter defaultCenter]
     postNotificationName: RSSReaderLogNotification
     object: @"Cannot find menu item for RSSReaderRemoveArticlesAfterDefaults"];
    [removeDateButton selectItemAtIndex: 3];
    [self removeDateAction: removeDateButton];
  }
}

@end

