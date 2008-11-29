#import <AppKit/AppKit.h>

@class AZMainLoop;

@interface AZApplication: NSObject
{
  AZMainLoop *mainLoop;
}

+ (AZApplication *) sharedApplication;

- (void) createAvailableCursors;

@end
