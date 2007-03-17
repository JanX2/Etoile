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
    if (mask & NSDragOperationMove) 
    {
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

- (BOOL) performDragOperation: (id <NSDraggingInfo>) sender
{
  NSPasteboard *pboard = [sender draggingPasteboard];
  NSDragOperation mask = [sender draggingSourceOperationMask];

  if ([[pboard types] containsObject: NSFilenamesPboardType]) 
  {
    if (mask & NSDragOperationMove) 
    {
      NSArray *files = [pboard propertyListForType: NSFilenamesPboardType];
      [[TrashCan sharedTrashCan] writeFiles: files];
    }
  }
  return YES;
}

#if 0
- (BOOL) prepareForDragOperation: (id <NSDraggingInfo>) sender
{
}
#endif

#if 0
- (BOOL) performDragOperation: (id <NSDraggingInfo>) sender
{
}
#endif

@end
