#import "TrashCanView.h"
#import "TrashCan.h"

@implementation TrashCanView

- (void) mouseDown: (NSEvent *) event
{
  /* Check for double click */
  NSLog(@"Here");
}

/* Drag and drop */
- (NSDragOperation) draggingEntered: (id <NSDraggingInfo>) sender
{
  NSPasteboard *pboard = [sender draggingPasteboard];
  NSDragOperation mask = [sender draggingSourceOperationMask];

  if ([[pboard types] containsObject: NSFilenamesPboardType]) 
  {
    NSLog(@"mask %d", mask);
    if (mask & NSDragOperationMove) 
    {
      NSLog(@"done");
      return NSDragOperationMove;
    }
  }
  return NSDragOperationNone;
}

#if 0
- (NSDragOperation) draggingUpdated: (id <NSDraggingInfo>) sender
{
}
#endif

#if 0
- (NSDragOperation) draggingExited: (id <NSDraggingInfo>) sender
{
}
#endif

- (BOOL) prepareForDragOperation: (id <NSDraggingInfo>) sender
{
  NSLog(@"prepare");
  return YES;
}

- (BOOL) performDragOperation: (id <NSDraggingInfo>) sender
{
  NSLog(@"perform");
  NSPasteboard *pboard = [sender draggingPasteboard];
  NSDragOperation mask = [sender draggingSourceOperationMask];

  if ([[pboard types] containsObject: NSFilenamesPboardType]) 
  {
    if (mask & NSDragOperationMove) 
    {
      NSArray *files = [pboard propertyListForType: NSFilenamesPboardType];
NSLog(@"TrashCan %@", files);
      [[TrashCan sharedTrashCan] writeFiles: files];
    }
  }
  return YES;
}

@end
