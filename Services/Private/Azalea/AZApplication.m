#import "AZApplication.h"
#import "openbox.h"
#import "AZMainLoop.h"

static AZApplication *sharedInstance;

@implementation AZApplication

- (void)receivedEvent:(void *)data
                 type:(RunLoopEventType)type
	        extra:(void *)extra
	      forMode:(NSString *)mode
{
  [mainLoop mainLoopRun];
  if ([mainLoop run] == NO)
  {
    [NSApp stop: self];
    return;
  }
}

- (void) applicationWillFinishLaunching:(NSNotification *)aNotification
{
  /* Listen event */
  NSRunLoop     *loop = [NSRunLoop currentRunLoop];
  int xEventQueueFd = XConnectionNumber(ob_display);

  [loop addEvent: (void*)(gsaddr)xEventQueueFd
            type: ET_RDESC
         watcher: (id<RunLoopEvents>)self
         forMode: NSDefaultRunLoopMode];

  mainLoop = [AZMainLoop mainLoop];
}

+ (AZApplication *) sharedApplication
{
  if (sharedInstance == nil)
  {
    sharedInstance = [[AZApplication alloc] init];
  }
  return sharedInstance;
}

@end
