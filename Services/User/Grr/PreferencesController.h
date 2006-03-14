/* All Rights reserved */

#include <AppKit/AppKit.h>

@interface PreferencesController : NSObject
{
  id webBrowserField;
  id preferencesWindow;
}
- (void) testWebBrowser: (id)sender;
- (void) setWebBrowser: (id)sender;
@end
