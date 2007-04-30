#import "OSBundleNode.h"

static NSArray *extensions;

@implementation OSBundleNode

- (BOOL) hasChildren
{
  return NO;
}

- (NSArray *) children
{
  return nil;
}

/* Accept double-click */
- (BOOL) doLaunching
{
  NSString *ext = [[self path] pathExtension];
  if ([ext isEqualToString: @"app"])
  {
    /* Let's try to launch it */
    BOOL success = [[NSWorkspace sharedWorkspace] launchApplication: [[self path] lastPathComponent]];
    if (success == NO)
    {
      NSLog(@"Fails to launch %@", [[self path] lastPathComponent]);
    }
    return success;
  }
  else
  {
    /* For other types, we do nothing */
  }
  return YES; /* return YES to avoid raising an alert */
}

+ (NSArray *) pathExtension
{
  if (extensions == nil)
  {
    extensions = [[NSArray alloc] initWithObjects: @"app", @"bundle", nil];
  }
  return extensions;
}

@end

