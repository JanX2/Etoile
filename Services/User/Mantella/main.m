#import "Controller.h"
#import <gtk/gtk.h>

int main(int argc, char **argv)
{
  gtk_init(&argc, &argv);

  CREATE_AUTORELEASE_POOL(pool);

  Controller *controller = [[Controller alloc] init];
  [NSApplication sharedApplication];

  [NSApp setDelegate: AUTORELEASE(controller)];
  [NSApp run];

  DESTROY(pool);

  return 0;
}

