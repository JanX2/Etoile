/* All Rights reserved */

#include <AppKit/AppKit.h>

@interface AppController : NSObject
{
  id list;
  id status;
  id resultsTests;
  id summary;
  id testedBundlePathTextfield;
  id ukrunPathTextfield;
  id preferencesPanel;

  NSString* testedBundlePath;
  NSString* ukrunPath;
}
- (void) showPrefPanel: (id)sender;
- (void) runTests: (id)sender;
@end
