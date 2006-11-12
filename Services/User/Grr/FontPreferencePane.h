#import <PaneKit/PaneKit.h>

@interface FontPreferencePane: PKPreferencePane
{
  NSTextField *systemFontField;
  NSTextField *systemFontSizeField;

  NSButton *useSystemFontButton;
  NSButton *useSystemFontSizeButton;

  NSPopUpButton *feedListFontButton;
  NSPopUpButton *feedListSizeButton;
  NSPopUpButton *articleListFontButton;
  NSPopUpButton *articleListSizeButton;
  NSPopUpButton *articleContentFontButton;
  NSPopUpButton *articleContentSizeButton;

  NSUserDefaults *defaults;
  NSFontManager *fontManager;
  NSArray *displayFontNamesCache; /* To display in user interface */
  NSArray *fontNamesCache; /* Internally and user defaults */

  BOOL anythingChanged;
}

- (void) fontAndSizeAction: (id) sender;
- (void) useSystemAction: (id) sender;

@end

