#import "CKTableView.h"

@implementation CKTableView (RSSReader)
- (void) keyDown: (NSEvent *) event
{
  unichar key = [[event charactersIgnoringModifiers] characterAtIndex: 0];
  if ((key == NSEnterCharacter) ||
      (key == NSCarriageReturnCharacter) ||
      (key == NSNewlineCharacter))
  {
    [[self delegate] enterKeyDownInTableView: self];
  } 
  [super keyDown: event];
}
@end

