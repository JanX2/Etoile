#import "OSTrashCanView.h"
#import "OSObjectFactory.h"

@implementation OSTrashCanView

- (id) initWithFrame: (NSRect) frame
{
  self = [super initWithFrame: frame];
  [self setImage: [NSImage imageNamed: @"TrashCan"]];
//  [self setTitle: @"Trash Can"];
//  [self setImagePosition: NSImageAbove];
  [self setBordered: NO];
  [self registerForDraggedTypes: 
                        [NSArray arrayWithObject: NSFilenamesPboardType]];
  return self;
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
      NSLog(@"Move");
      return NSDragOperationMove;
    }
  }
  return NSDragOperationNone;
}

- (BOOL) prepareForDragOperation: (id <NSDraggingInfo>) sender
{
  return YES;
}

- (BOOL) performDragOperation: (id <NSDraggingInfo>) sender
{
  NSPasteboard *pboard = [sender draggingPasteboard];
  NSDragOperation mask = [sender draggingSourceOperationMask];

  if ([[pboard types] containsObject: NSFilenamesPboardType]) 
  {
    if (mask & NSDragOperationMove) 
    {
      OSObjectFactory *factory = [OSObjectFactory defaultFactory];
      OSTrashCan *trashCan = [factory trashCan];
      NSEnumerator *e = [[pboard propertyListForType: NSFilenamesPboardType] objectEnumerator];
      NSString *p = nil;
      while ((p = [e nextObject]))
      {
	id <OSObject> object = [factory objectAtPath: p];
	if (object)
	{
	  /* We see whether it will be accept */
	  if ([trashCan willAcceptChild: object error: NULL])
	  {
	    if ([trashCan doAcceptChild: object move: YES error: NULL])
	    {
	      return YES;
	    }
	  }
	}
      }
    }
  }
  return NO;
}

@end

