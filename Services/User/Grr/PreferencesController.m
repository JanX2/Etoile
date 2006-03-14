/* All Rights reserved */

#include <AppKit/AppKit.h>
#include "PreferencesController.h"

@implementation PreferencesController

- (void) bringUpWindow: (id)sender
{
  [webBrowserField
    setStringValue:
      [[NSUserDefaults standardUserDefaults] stringForKey: @"WebBrowser"] ];
  
  [preferencesWindow orderFront: self];
}


- (void) testWebBrowser: (id)sender
{
  [[NSWorkspace sharedWorkspace]
    openURL:
      [NSURL URLWithString: @"http://www.unix-ag.uni-kl.de/~guenther/"]];
}


- (void) setWebBrowser: (id)sender
{
  [[NSUserDefaults standardUserDefaults]
    setObject: [webBrowserField stringValue]
    forKey: @"WebBrowser"];
}

@end
