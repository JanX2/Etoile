#import <AppKit/AppKit.h>

int main(int argc, const char *argv[]) 
{
  CREATE_AUTORELEASE_POOL(x);

  /* Hide App Icon */
  [[NSUserDefaults standardUserDefaults]
    setObject: [NSNumber numberWithBool: YES] forKey: @"GSSuppressAppIcon"];

  int result = NSApplicationMain (argc, argv);
  DESTROY(x);
  return result;
}
