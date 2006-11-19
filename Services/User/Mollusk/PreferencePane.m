#import "PreferencePane.h"
#import "Global.h"
#import "GNUstep.h"

float intervals[11] = {0.5, 1, 2, 3, 4, 6, 8, 12, 16, 24, -1};

@implementation PreferencePane

- (void) fetchAtStartupAction: (id) sender
{
  [defaults setBool: [fetchAtStartupButton state] 
             forKey: RSSReaderFetchAtStartupDefaults];
}

- (void) intervalAction: (id) sender
{
  int value = [sender intValue];
  float interval = intervals[value];

  if (interval < 0) {
    [intervalField setStringValue: @"Never"];
  } else if (interval < 1) {
    [intervalField setStringValue: [NSString stringWithFormat: @"%d minutes", (int)(interval*60)]];
  } else {
    [intervalField setStringValue: [NSString stringWithFormat: @"%d hours", (int)interval]];
  }

  /* Do not update user defaults here because it is called frequently.
   * Do that in -willUnselect */
  anythingChanged = YES;
}

- (void) webBrowserAction: (id) sender
{
  [defaults setObject: [webBrowserField stringValue] 
                  forKey: RSSReaderWebBrowserDefaults];
}

- (void) testWebBrowserAction: (id) sender
{
  [[NSWorkspace sharedWorkspace] openURL:
      [NSURL URLWithString: @"http://www.unix-ag.uni-kl.de/~guenther/"]];
}

- (void) removeDateAction: (id) sender
{
  int number = [[sender selectedItem] tag];
  [defaults  setInteger: number
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
  /* For some reason, _mainView has to be retained !! */
  ASSIGN(_mainView, [_window contentView]);
  RETAIN(_mainView);

  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
         @"01General", @"identifier",
         @"General", @"name",
         @"01General", @"path",
         [NSValue valueWithPointer: [self class]], @"class",
         self, @"instance", nil];
  [[PKPreferencePaneRegistry sharedRegistry] addPlugin: dict];

  ASSIGN(defaults, [NSUserDefaults standardUserDefaults]);
  
  return self;
}

- (void) dealloc
{
  DESTROY(defaults);
  [super dealloc];
}

- (void) willSelect
{
  /* Set fetch at startup */
  [fetchAtStartupButton setState: [defaults boolForKey: RSSReaderFetchAtStartupDefaults]];
  
  /* Set interval. To ease the potential */
  float f = [defaults floatForKey: RSSReaderAutomaticRefreshIntervalDefaults];
  int i;
  for (i = 0; i < 11; i++) {
    if (f == intervals[i]) {
      [intervalSlider setIntValue: i];
      [self intervalAction: intervalSlider];
      break;
    }
  }

  /* Set web browser */
  [webBrowserField setStringValue: [defaults stringForKey: RSSReaderWebBrowserDefaults]];

  /* Set remove older article */
  int number = [defaults integerForKey: RSSReaderRemoveArticlesAfterDefaults];
  /* Find the item with the right tag */
  BOOL found = NO;
  int count = [removeDateButton numberOfItems];
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
  anythingChanged = NO;
}

- (void) willUnselect
{
  if (anythingChanged == YES) {
    int value = [intervalSlider intValue];
    float interval = intervals[value];
    [defaults setFloat: interval
              forKey: RSSReaderAutomaticRefreshIntervalDefaults];
    [[NSNotificationCenter defaultCenter] 
      postNotificationName: RSSReaderAutomaticRefreshIntervalChangeNotification
      object: self];
  }
  anythingChanged = NO;
}

@end

