/* All Rights reserved */
// -*-objc-*-

#import <AppKit/AppKit.h>

@interface ErrorLogController : NSObject
{
  id logWindow;
  id logWidget;
}

- init;

+ (ErrorLogController*) instance;
- (void) clearLog: (id)sender;
- (void) logString: (NSString*) aString;

@end

