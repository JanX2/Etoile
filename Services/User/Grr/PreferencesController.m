/* All Rights reserved */

#include <AppKit/AppKit.h>
#include "PreferencesController.h"

@implementation PreferencesController

-(id) init
{
  if ((self = [super init]) != nil) {
    [[NSNotificationCenter defaultCenter]
      addObserver: self
      selector: @selector(bringUpWindow:)
      name: @"PreferencesToBeOpenedNotification"
      object: nil];
  }
  
  return self;
}

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
