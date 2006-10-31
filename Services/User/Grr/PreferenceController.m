#import <AppKit/AppKit.h>
#import "PreferenceController.h"
#import "GNUstep.h"

static PreferenceController *sharedInstance;

@implementation PreferenceController

+ (PreferenceController *) preferenceController
{
  if (sharedInstance == nil) {
    sharedInstance = [[PreferenceController alloc] init];
  }
  return sharedInstance;
}

-(id) init
{
  self = [super init];
  
  return self;
}

- (void) awakeFromNib
{
}

- (void) showPreferencePanel: (id) sender
{
  if (preferencePanel == nil) {
    [NSBundle loadNibNamed: @"Preferences" owner: self];
    [preferencePanel setFrameAutosaveName: @"prefPanel"];
  }

  [webBrowserField setStringValue:
      [[NSUserDefaults standardUserDefaults] stringForKey: @"WebBrowser"] ];
  
  [preferencePanel orderFront: self];
}


- (void) testWebBrowser: (id)sender
{
  [[NSWorkspace sharedWorkspace] openURL:
      [NSURL URLWithString: @"http://www.unix-ag.uni-kl.de/~guenther/"]];
}


- (void) setWebBrowser: (id)sender
{
  [[NSUserDefaults standardUserDefaults]
    setObject: [webBrowserField stringValue] forKey: @"WebBrowser"];
}

@end
