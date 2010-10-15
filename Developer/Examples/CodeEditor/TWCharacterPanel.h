#import <AppKit/AppKit.h>

@interface TWCharacterPanel: NSPanel
{
  NSPopUpButton *button;
  NSScrollView *scrollView;
  NSMatrix *matrix;
  NSPanel *panel;

  NSFontManager *fm;
  NSArray *availableFontFamilies;
  NSFont *font;
}

+ (TWCharacterPanel *) sharedCharacterPanel;

- (NSMatrix *) matrix;
- (NSFont *) selectedFont;

@end

@interface NSObject (TWCharacterPanelAction)
- (void) characterSelectedInPanel: (id) sender;
@end
