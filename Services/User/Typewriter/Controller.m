#import "Controller.h"
#import "TWDocument.h"

@implementation Controller

- (void) applicationDidFinishLaunching: (NSNotification *) not
{
  [NSApp setServicesProvider: self];
}

/* Services */
- (void) newDocumentWithSelection: (NSPasteboard *) pboard
                         userData: (NSString *) userData
                            error: (NSString **) error
{
  NSDocumentController *docController = [NSDocumentController sharedDocumentController];
  if ([[pboard types] containsObject: NSStringPboardType])
  {
    /* Should be string */
    NSString *string = [pboard stringForType: NSStringPboardType];
    if (string)
    {
      TWDocument *doc = (TWDocument *)[docController openUntitledDocumentOfType: @"TWRTFTextType" display: YES];
      [doc appendString: string];
    }
  }
}

@end

