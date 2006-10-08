#import "Controller.h"
#import <gst/gst.h>

int main(int argc, char **argv)
{
  gst_init(&argc, &argv);

  CREATE_AUTORELEASE_POOL(pool);

  Controller *controller = [[Controller alloc] init];
  [NSApplication sharedApplication];

  [NSApp setDelegate: AUTORELEASE(controller)];
  [NSApp run];

  DESTROY(pool);

  return 0;
}

