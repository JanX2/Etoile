#import <TWCharacterPanel.h>

static TWCharacterPanel *sharedInstance;

@implementation TWCharacterPanel

/** Private **/

- (void) displayCharacters
{
  unsigned int columns, rows, width = 15; /* size of cell */
  unsigned int numberOfGlyphs;
  int j, c, r;
  unichar i;
  NSRect rect = [matrix bounds];
  NSTextFieldCell *cell;
  NSCharacterSet *cSet = [font coveredCharacterSet];
  NSString *s;

  numberOfGlyphs = [font numberOfGlyphs];
  columns = (rect.size.width / width) - 1;
  rows = (numberOfGlyphs / columns) + 1;
  cell = [[NSTextFieldCell alloc] initTextCell: nil];
  [cell setAlignment: NSCenterTextAlignment];
  [cell setTarget: self];
  [cell setAction: @selector(matrixAction:)];
  [matrix setPrototype: cell];
  [matrix setCellSize: NSMakeSize(width, width)];
  [matrix renewRows: rows columns: columns];
  DESTROY(cell);

  for (i = 0, j = 0; j < numberOfGlyphs; i++) {
    if ([cSet characterIsMember: i] == YES) {
      j++;
      r = j / columns;
      c = j - (r * columns);
      cell = [matrix cellAtRow: r column: c];
      s = [NSString stringWithCharacters: &i length: 1];
      [cell setFont: font];
      [cell setStringValue: [NSString stringWithCharacters: (unichar*)&i length: 1]];
    }
  }
  [matrix setNeedsDisplay: YES];
  [matrix sizeToCells];
  [matrix scrollCellToVisibleAtRow: 0 column: 0];
}

/** End of Private **/

- (void) buttonAction: (id) sender
{
  int index = [sender indexOfSelectedItem];
  NSString *name = [[[fm availableMembersOfFontFamily: [availableFontFamilies objectAtIndex: index]] objectAtIndex: 0] objectAtIndex: 0];
  font = [fm convertFont: [NSFont fontWithName: name size: 12]
	     toNotHaveTrait: NSItalicFontMask|NSBoldFontMask];
  [self displayCharacters];
}

/* Action from cell */
- (void) matrixAction: (id) sender
{
  [NSApp sendAction: @selector(characterSelectedInPanel:)
	         to: nil
	       from: self];
}

- (void) awakeFromNib
{
  ASSIGNCOPY(availableFontFamilies, [fm availableFontFamilies]);
  [button removeAllItems];
  [button addItemsWithTitles: availableFontFamilies];
  [button selectItemAtIndex: 0];
  [self buttonAction: button];
}

- (id) initWithContentRect: (NSRect)contentRect
                 styleMask: (unsigned int)aStyle
	           backing: (NSBackingStoreType)bufferingType
	             defer: (BOOL)flag
	            screen: (NSScreen*)aScreen
{
  self = [super initWithContentRect: contentRect
	                  styleMask: aStyle
			    backing: bufferingType
			      defer: flag
			     screen: aScreen];
  fm = [NSFontManager sharedFontManager];
  return self;
}

- (void) orderFront: (id) sender
{
  if (panel == nil) {
    if ([NSBundle loadNibNamed: @"CharacterPanel" owner: self] == NO) {
      NSLog(@"Cannot load nib for character panel");
    }
  }
  [panel orderFront: self];
}

- (void) dealloc
{
  DESTROY(availableFontFamilies);
  [super dealloc];
}

- (NSMatrix *) matrix
{
  return matrix;
}

- (NSFont *) selectedFont
{
  return font;
}

+ (TWCharacterPanel *) sharedCharacterPanel
{
  if (sharedInstance == nil) {
	  sharedInstance = [[TWCharacterPanel alloc] init];
  }
  return sharedInstance;
}

@end
