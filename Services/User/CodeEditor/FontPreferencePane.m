#import "FontPreferencePane.h"
#import "GNUstep.h"

@implementation FontPreferencePane

- (void) fontAndSizeAction: (id) sender
{
//  NSLog(@"%@", NSStringFromSelector(_cmd));
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

  NSArray *sizes= [NSArray arrayWithObjects: @"7", @"8", @"9", @"10", @"11", @"12", @"13", @"14", @"16", @"18", @"20", @"22", @"24", @"26", @"28", nil];

  [fontNameButton removeAllItems];
  [fontNameButton addItemsWithTitles: displayFontNamesCache];
  [fontSizeButton removeAllItems];
  [fontSizeButton addItemsWithTitles: sizes];

  {
    /* Here, we set up the system default value
     * in case later on, the user defaults has invalid value
     * because the changing of fonts in the system (font is removed, etc).
     */
    int size = [NSFont systemFontSize];
    NSString *s = [NSString stringWithFormat: @"%d", size];
    [fontSizeButton selectItemWithTitle: s];

    NSFont *f = [NSFont systemFontOfSize: size];
//    f = [fontManager convertFont: f toHaveTrait: NSFixedPitchFontMask];
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
    [fontNameButton selectItemWithTitle: s];
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
  NSString *s = [defaults stringForKey: CodeEditorFontNameDefaults];
  if (s) {
    [fontNameButton selectItemWithTitle: s];
  }
  s = [defaults stringForKey: CodeEditorFontSizeDefaults];
  if (s) {
    [fontSizeButton selectItemWithTitle: s];
  }
  anythingChanged = NO;
}

- (void) willUnselect
{
  if (anythingChanged == YES) {
    int index = [fontNameButton indexOfSelectedItem];
    [defaults setObject: [fontNamesCache objectAtIndex: index]
                 forKey: CodeEditorFontNameDefaults];
    [defaults setObject: [fontSizeButton titleOfSelectedItem]
                 forKey: CodeEditorFontSizeDefaults];
    [[NSNotificationCenter defaultCenter]
                 postNotificationName: CodeEditorFontChangeNotification
                 object: self];
  }
  anythingChanged = NO;
}

@end

NSString *const CodeEditorFontNameDefaults = @"CodeEditorFontNameDefaults";
NSString *const CodeEditorFontSizeDefaults = @"CodeEditorFontSizeDefaults";
NSString *const CodeEditorFontChangeNotification = @"CodeEditorFontChangeNotification";

