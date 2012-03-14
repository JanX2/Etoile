#import <Foundation/Foundation.h>

int
main()
{
  id pool = [NSAutoreleasePool new];
  [[NSClassFromString(@"SmalltalkTool") new] run];
  [pool release];
  return 0;
}
