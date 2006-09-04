#import "AZDock.h"

int main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(pool);

  // we never show the app icon
  [[NSUserDefaults standardUserDefaults]
      setObject: [NSNumber numberWithBool: YES] forKey: @"GSSuppressAppIcon"];

  AZDock *dock = [AZDock sharedDock];
  [NSApplication sharedApplication];
      
  [NSApp setDelegate: dock];    
  [NSApp run];   

  DESTROY(pool);

  return 0;
}

