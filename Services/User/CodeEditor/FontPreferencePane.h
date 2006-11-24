#import <PaneKit/PaneKit.h>

extern NSString *const CodeEditorFontNameDefaults;
extern NSString *const CodeEditorFontSizeDefaults;
extern NSString *const CodeEditorFontChangeNotification;

@interface FontPreferencePane: PKPreferencePane
{
  NSPopUpButton *fontNameButton;
  NSPopUpButton *fontSizeButton;
  BOOL anythingChanged;

  NSArray *displayFontNamesCache; /* To display in user interface */
  NSArray *fontNamesCache; /* Internally and user defaults */

  NSUserDefaults *defaults;
  NSFontManager *fontManager;

}

- (void) fontAndSizeAction: (id) sender;

@end

