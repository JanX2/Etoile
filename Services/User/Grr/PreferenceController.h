#include <AppKit/AppKit.h>

@interface PreferenceController : NSObject
{
  id webBrowserField;
  id preferencePanel;
}

+ (PreferenceController *) preferenceController;

- (void) testWebBrowser: (id)sender;
- (void) setWebBrowser: (id)sender;
- (void) showPreferencePanel: (id) sender;

@end
