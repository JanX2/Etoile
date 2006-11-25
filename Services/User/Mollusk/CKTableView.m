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
    return;
  } 
  else if (key == NSLeftArrowFunctionKey)
  {
    [[self window] makeFirstResponder: [self nextKeyView]];
    return;
  } 

  [super keyDown: event];
}
@end

