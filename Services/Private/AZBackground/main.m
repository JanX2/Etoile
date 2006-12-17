#import "AZBackground.h"

int main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(pool);

  [[NSUserDefaults standardUserDefaults]
      setObject: [NSNumber numberWithBool: YES] 
         forKey: @"GSSuppressAppIcon"];

  [NSApplication sharedApplication];
      
  [NSApp setDelegate: [AZBackground background]];    
  [NSApp run];   

  DESTROY(pool);

  return 0;
}

