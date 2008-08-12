#import "Controller.h"
#import "TWDocument.h"
#import <ScriptKit/ScriptCenter.h>

@implementation Controller

- (void) applicationDidFinishLaunching: (NSNotification *) not
{
  [NSApp setServicesProvider: self];
  [[ScriptCenter sharedInstance] enableScripting];
}

/* Services */
- (void) openDocumentWithPath: (NSPasteboard *) pboard
                     userData: (NSString *) userData
                        error: (NSString **) error
{
  if ([[pboard types] containsObject: NSStringPboardType])
  {
    /* Should be string */
    NSString *string = [pboard stringForType: NSStringPboardType];
    if (string)
    {
      NSDocumentController *docController = [NSDocumentController sharedDocumentController];
      [docController openDocumentWithContentsOfFile: [string stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]]
                                            display: YES];
    }
  }
}

- (void) newDocumentWithSelection: (NSPasteboard *) pboard
                         userData: (NSString *) userData
                            error: (NSString **) error
{
  if ([[pboard types] containsObject: NSStringPboardType])
  {
    /* Should be string */
    NSString *string = [pboard stringForType: NSStringPboardType];
    if (string)
    {
      NSDocumentController *docController = [NSDocumentController sharedDocumentController];
      TWDocument *doc = (TWDocument *)[docController openUntitledDocumentOfType: @"TWRTFTextType" display: YES];
      [doc appendString: string];
    }
  }
}

@end

