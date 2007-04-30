#import "Controller.h"

int main(int argc, const char *argv[])
{
  CREATE_AUTORELEASE_POOL(x);

  [NSApplication sharedApplication];
  [NSApp setDelegate: AUTORELEASE([[Controller alloc] init])];
  [NSApp run];

  DESTROY(x);

  return 0;
}

