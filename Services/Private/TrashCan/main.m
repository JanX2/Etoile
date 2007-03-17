#import "TrashCan.h"

int main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(pool);

  [NSApplication sharedApplication];
      
  [NSApp setDelegate: [TrashCan sharedTrashCan]];    
  [NSApp run];   

  DESTROY(pool);

  return 0;
}

