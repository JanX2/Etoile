#import "FontPreferencePane.h"
#import "Global.h"
#import "GNUstep.h"

@implementation FontPreferencePane

- (void) fontAndSizeAction: (id) sender
{
  anythingChanged = YES;
}

- (void) useSystemAction: (id) sender
{
  BOOL enabled = YES;
  if ([sender state] == NSOnState) {
    /* Disable font button */
    enabled = NO;
  } else {
    enabled = YES;
  }
  if (sender == useSystemFontButton) {
    [feedListFontButton setEnabled: enabled];
    [articleListFontButton setEnabled: enabled];
    [articleContentFontButton setEnabled: enabled];
  } else if (sender == useSystemFontSizeButton) {
    [feedListSizeButton setEnabled: enabled];
    [articleListSizeButton setEnabled: enabled];
    [articleContentSizeButton setEnabled: enabled];
  }
  anythingChanged = YES;
}

- (id) init 
{
  self = [super init];

  if ([NSBundle loadNibNamed: @"FontPreferencePane" owner: self] == NO) {
    NSLog(@"Failed to load nib file");
    [self dealloc];
    return nil;
  }
  ASSIGN(_mainView, [_window contentView]);
  RETAIN(_mainView);

  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
         @"02Font", @"identifier",
         @"Font", @"name",
         @"02Font", @"path",
         [NSValue valueWithPointer: [self class]], @"class",
         self, @"instance", nil];
  [[PKPreferencePaneRegistry sharedRegistry] addPlugin: dict];

  ASSIGN(defaults, [NSUserDefaults standardUserDefaults]);
  ASSIGN(fontManager, [NSFontManager sharedFontManager]);

  NSArray *fonts = [[fontManager availableFontNamesWithTraits: 0] sortedArrayUsingSelector: @selector(compare:)];
  ASSIGN(fontNamesCache, fonts);
  NSMutableArray *ma = [[NSMutableArray alloc] init];
  NSEnumerator *e = [fontNamesCache objectEnumerator];
  NSString *s;
  while ((s = [e nextObject])) {
    s = [fontManager localizedNameForFamily: s face: nil];
    if (s) {
      [ma addObject: s];
    } else {
      NSLog(@"Error: not localized name for family");
    }
  }
  ASSIGN(displayFontNamesCache, [NSArray arrayWithArray: ma]);
  DESTROY(ma);

  /* Set font */
  NSArray *sizes= [NSArray arrayWithObjects: @"7", @"8", @"9", @"10", @"11", @"12", @"13", @"14", @"16", @"18", @"20", @"22", @"24", @"36", @"48", nil];

  [feedListSizeButton removeAllItems];
  [articleListSizeButton removeAllItems];
  [articleContentSizeButton removeAllItems];
  [feedListSizeButton addItemsWithTitles: sizes];
  [articleListSizeButton addItemsWithTitles: sizes];
  [articleContentSizeButton addItemsWithTitles: sizes];

  [feedListFontButton removeAllItems];
  [articleListFontButton removeAllItems];
  [articleContentFontButton removeAllItems];
  [feedListFontButton addItemsWithTitles: displayFontNamesCache];
  [articleListFontButton addItemsWithTitles: displayFontNamesCache];
  [articleContentFontButton addItemsWithTitles: displayFontNamesCache];
  
  {
    /* Here, we set up the system default value
     * in case later on, the user defaults has invalid value
     * because the changing of fonts in the system (font is removed, etc).
     */
    int size = [NSFont systemFontSize];
    NSFont *f = [NSFont systemFontOfSize: size];
    NSString *s = [NSString stringWithFormat: @"%d", size];
    [feedListSizeButton selectItemWithTitle: s];
    [articleListSizeButton selectItemWithTitle: s];
    [articleContentSizeButton selectItemWithTitle: s];
    s = [f fontName];
#ifdef GNUSTEP
    NSEnumerator *e = [displayFontNamesCache objectEnumerator];
    s = nil;
    while ((s = [e nextObject])) {
      if ([s hasPrefix: [f fontName]]) {
        break;
      }
    }
    if (s == nil) {
      /* Cannot find the right name */
      s = [displayFontNamesCache objectAtIndex: 0];
    }
#endif
    [feedListFontButton selectItemWithTitle: s];
    [articleListFontButton selectItemWithTitle: s];
    [articleContentFontButton selectItemWithTitle: s];

    [systemFontField setStringValue: [NSString stringWithFormat: @"( %@ )", [f fontName]]];
    [systemFontSizeField setStringValue: [NSString stringWithFormat: @"( %d )", size]];
  }
  
  return self;
}

- (void) dealloc
{
  DESTROY(defaults);
  DESTROY(fontManager);
  DESTROY(displayFontNamesCache);
  DESTROY(fontNamesCache);
  [super dealloc];
}

- (void) willSelect
{
  BOOL b = [defaults boolForKey: RSSReaderUseSystemFontDefaults];
  [useSystemFontButton setState: b];
  [self useSystemAction: useSystemFontButton];

  b = [defaults boolForKey: RSSReaderUseSystemSizeDefaults];
  [useSystemFontSizeButton setState: b];
  [self useSystemAction: useSystemFontSizeButton];

  NSString *s = [defaults stringForKey: RSSReaderFeedListSizeDefaults];
  if (s) {
    [feedListSizeButton selectItemWithTitle: s];
  }
  s = [defaults stringForKey: RSSReaderArticleListSizeDefaults];
  if (s) {
    [articleListSizeButton selectItemWithTitle: s];
  }
  s = [defaults stringForKey: RSSReaderArticleContentSizeDefaults];
  if (s) {
    [articleContentSizeButton selectItemWithTitle: s];
  } 
  s = [defaults stringForKey: RSSReaderFeedListFontDefaults];
  if (s) {
    s = [displayFontNamesCache objectAtIndex: [fontNamesCache indexOfObject: s]];
    [feedListFontButton selectItemWithTitle: s];
  }
  s = [defaults stringForKey: RSSReaderArticleListFontDefaults];
  if (s) {
    s = [displayFontNamesCache objectAtIndex: [fontNamesCache indexOfObject: s]];
    [articleListFontButton selectItemWithTitle: s];
  }
  s = [defaults stringForKey: RSSReaderArticleContentFontDefaults];
  if (s) {
    s = [displayFontNamesCache objectAtIndex: [fontNamesCache indexOfObject: s]];
    [articleContentFontButton selectItemWithTitle: s];
  } 
  anythingChanged = NO;
}

- (void) willUnselect
{
  if (anythingChanged == YES) {
    [defaults setBool: [useSystemFontButton state]
               forKey: RSSReaderUseSystemFontDefaults];
    [defaults setBool: [useSystemFontSizeButton state]
               forKey: RSSReaderUseSystemSizeDefaults];

    int index = [feedListFontButton indexOfSelectedItem];
    [defaults setObject: [fontNamesCache objectAtIndex: index]
                 forKey: RSSReaderFeedListFontDefaults];
    index = [articleListFontButton indexOfSelectedItem];
    [defaults setObject: [fontNamesCache objectAtIndex: index]
                 forKey: RSSReaderArticleListFontDefaults];
    index = [articleContentFontButton indexOfSelectedItem];
    [defaults setObject: [fontNamesCache objectAtIndex: index]
                 forKey: RSSReaderArticleContentFontDefaults];

    [defaults setObject: [feedListSizeButton titleOfSelectedItem]
                 forKey: RSSReaderFeedListSizeDefaults];
    [defaults setObject: [articleListSizeButton titleOfSelectedItem]
                 forKey: RSSReaderArticleListSizeDefaults];
    [defaults setObject: [articleContentSizeButton titleOfSelectedItem]
                 forKey: RSSReaderArticleContentSizeDefaults];
    [[NSNotificationCenter defaultCenter]
                 postNotificationName: RSSReaderFontChangeNotification
                 object: self];
  }
  anythingChanged = NO;
}

@end

