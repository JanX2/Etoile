#import "OSDistributedView.h"
#import "OSDistributedCell.h"
#import <math.h>

@implementation OSDistributedView
/* Private */
- (void) _buildCells
{
  int i, count = [dataSource numberOfObjectsInDistributedView: self];
  NSMutableArray *newArray = [[NSMutableArray alloc] init];
  /* We need to reuse cells so that their properties stays */
  for (i = 0; i < count; i++)
  {
    id node = [dataSource distributedView: self objectAtIndex: i];
    /* Do we have this node already ? */
    NSEnumerator *e = [cells objectEnumerator];
    OSDistributedCell *cell = nil;
    BOOL found = NO;
    while ((cell = [e nextObject]))
    {
      if ([node isEqual: [cell object]])
      {
        /* Old node. Put into new array */
	[newArray addObject: cell];
	found = YES;
	break;
      }
    }
    if (found == NO)
    {
      /* New node */
      OSDistributedCell *c = [[OSDistributedCell alloc] init]; 
      [c setObject: node];
      [newArray addObject: c];
      DESTROY(c);
    }
  }
  [cells setArray: newArray];
  DESTROY(newArray);
}

- (void) _distributeCells
{
  int count = [cells count];
  if (count == 0)
    return;

  int i, j, icount, jcount, index = 0;
  int iw, ih, w, h;
  BOOL end = NO, available = YES;
  /* We put up an array. Each bit represent a certain size.
     We mark it when a preview occupies certain size.
     We initiates with larger space just in case. 
   */
  unsigned char *bytes = NULL;
  NSPoint p = NSZeroPoint;
  NSSize visibleSize = [[self enclosingScrollView] documentVisibleRect].size;
  /* Calculate number of columns */
//  jcount = floor([[self enclosingScrollView] frame].size.width / CELL_SIZE);
  jcount = floor((visibleSize.width) / CELL_SIZE);
  icount = (floor(count / jcount)+1)*4; /* four times of spaces */
  bytes = malloc(sizeof(unsigned char)*icount*jcount);
  bzero(bytes, icount*jcount);

  for (i = 0; i < icount; i++)
  {
    for (j = 0; j < jcount; j++)
    {
      OSDistributedCell *cell = [cells objectAtIndex: index];
      NSSize size = [cell cellSize];
      w = floor(size.width/CELL_SIZE)+1;
      h = floor(size.height/CELL_SIZE)+1;
      /* Make sure we have enough space */
      available = YES;
      for (iw = 0; iw < w; iw++)
      {
        for (ih = 0; ih < h; ih++)
        {
          if (((i+ih) >= icount) || ((j+iw) >= jcount))
          {
            available = NO;
	    break;
          }
          else if (bytes[(i+ih) * jcount + (j+iw)] == YES)
          {
            available = NO;
	    break;
          }
        }
	if (available == NO)
          break;
      }
      if (available == NO)
        continue;

      p.x = j * CELL_SIZE;
      p.y = i * CELL_SIZE;
      [cell setOrigin: p];

      /* We mark bytes */
      for (iw = 0; iw < w; iw++)
      {
        for (ih = 0; ih < h; ih++)
        {
           bytes[(i+ih) * jcount + (j+iw)] = YES;
        }
      }

      index++;

      /* In case we are out of objects */
      if (index >= count)
      {
        end = YES;
        break;
      }
    }
    if (end == YES)
      break;
  }

  /* We use extra CELL_SIZE just in case */
  visibleSize.height = p.y + 2*CELL_SIZE;
  [self setFrameSize: visibleSize];

  free(bytes);
  bytes = NULL;
}

- (OSDistributedCell *) _cellAtLocation: (NSPoint) location
{
  NSEnumerator *e = [cells objectEnumerator];
  OSDistributedCell *cell;
  while ((cell = [e nextObject]))
  {
    NSRect rect = NSZeroRect;
    rect.origin = [cell origin];
    rect.size = [cell cellSize];
    if (NSMouseInRect(location, rect, [self isFlipped]))
    {
      return cell;
    } 
  }
  return nil;
}

- (NSImage *) _imageForDraggingSource
{
  /* Let's draw up to 5 icons in an image */
  NSArray *array = [self selectedCells];
  OSDistributedCell *cell = nil;
  NSRect rect = NSZeroRect;
  int i, count = [array count];
  int shift = 5;

  if (count < 1)
    return nil;

  /* See how big the icon */
  NSSize iconSize = [[[[array objectAtIndex: 0] object] icon] size];
  NSSize size = NSMakeSize(iconSize.width+(count-1)*shift,
                           iconSize.height+(count-1)*shift);
  if ((size.width < 5) || (size.height < 5))
    NSLog(@"Internal Error: drag image is less than 5x5");

  /* Draw on an image */
  NSImage *image = [[NSImage alloc] initWithSize: size];
  [image lockFocus];

  [[NSColor yellowColor] set];
  rect.size = size;
  NSRectFill(rect);
  for (i = 0; (i < count) && (i < 5); i++)
  {
    cell = [array objectAtIndex: i];
    [[[cell object] icon] 
              drawAtPoint: NSMakePoint(i*shift, i*shift)
              fromRect: NSMakeRect(0, 0, iconSize.width, iconSize.height)
              operation: NSCompositeSourceOver
              fraction: 1.0];
  }
  [image unlockFocus];
  return AUTORELEASE(image);
  
#if 0 
  // This is an attempt to draw cell on an image but it does not work perfect
  /* It returns an image for dragging.
     It basically go through all selected cells
     and drag it on a NSImage. */
  /* Figure out how big the image has to be */
  NSArray *array = [self selectedCells];
  OSDistributedCell *cell = nil;
  NSRect rect = NSZeroRect, cellFrame;
  NSPoint minPoint = NSMakePoint(1000000, 1000000);
  NSPoint maxPoint = NSZeroPoint;
  int i;
  for (i = 0; i < [array count]; i++)
  {
    cell = [array objectAtIndex: i];
    cellFrame.origin = [cell origin];
    cellFrame.size = [cell cellSize];
    if (NSMinX(cellFrame) < minPoint.x)
      minPoint.x = NSMinX(cellFrame);
    if (NSMinY(cellFrame) < minPoint.y)
      minPoint.y = NSMinY(cellFrame);
    if (NSMaxX(cellFrame) > maxPoint.x)
      maxPoint.x = NSMaxX(cellFrame);
    if (NSMaxY(cellFrame) > maxPoint.y)
      maxPoint.y = NSMaxY(cellFrame);
  } 
  rect = NSMakeRect(0, 0, maxPoint.x-minPoint.x, maxPoint.y-minPoint.y);
  /* Draw on an image */
  NSImage *image = [[NSImage alloc] initWithSize: rect.size];
//  [image setFlipped: YES];
  [image lockFocus];
  [[NSColor yellowColor] set];
  NSRectFill(rect);
  for (i = 0; i < [array count]; i++)
  {
    cell = [array objectAtIndex: i];
    cellFrame.origin = [cell origin];
    cellFrame.origin.x -= minPoint.x;
    cellFrame.origin.y -= minPoint.y;
    /* It is flippaed. We need to compensate it */
    cellFrame.origin.y = cellFrame.size.height-cellFrame.origin.y;
    cellFrame.size = [cell cellSize];
    [cell drawWithFrame: cellFrame inView: self];
  }
  [image unlockFocus];
  return AUTORELEASE(image);
#endif
}

/* End of Private */

/* Action */
- (void) mouseDown: (NSEvent *) event
{
//  [super mouseDown: event];

  int clickCount = [event clickCount];
  NSEventType type = [event type];
  unsigned int modifier = [event modifierFlags];
  NSPoint location = [self convertPoint: [event locationInWindow] 
                               fromView: nil];
  OSDistributedCell *cell = [self _cellAtLocation: location];
  if (type == NSLeftMouseDown)
  {
    OSDistributedCell *c = nil;
    NSEnumerator *e = nil;
   
    if (cell)
    {
      if (clickCount == 1)
      {
        /* Selection */
	/* We support two selection here. 
           Left-click to select single cell. Select empty space to deselect it.
	   Shift-left-click to add more cells into selection.
	   Shift-left-click to toggle selection.
	   There is not continuous selection by selecting first and last cell.
	   Always select one-by-one.
         */
        if (modifier & NSShiftKeyMask)
        {
	  /* Shift-left-click */
	  /* Adding more cell to selection */
          if ([selectedCells containsObject: cell])
          {
            /* Cell is selected, Deselect it */
            [cell setState: NSOffState];
	    [selectedCells removeObject: cell];
          }
          else
          {
            /* Cell is not selected. Select it */
	    [cell setState: NSOnState];
	    [selectedCells addObject: cell];
          }
        }
        else
        {
          /* Select single cell. Deselect all cells and select new one */
	  e = [selectedCells objectEnumerator];
	  while ((c = [e nextObject]))
	  {
 	    [c setState: NSOffState];
	  }
	  [selectedCells removeAllObjects];
          [cell setState: NSOnState];
	  [selectedCells addObject: cell];
        }
        if ([delegate respondsToSelector: @selector(distributedView:didSelectObjects:)])
        {
          NSMutableArray *os = [[NSMutableArray alloc] init];
          NSEnumerator *ce = [selectedCells objectEnumerator];
          OSDistributedCell *c = nil;
          while ((c = [ce nextObject]))
          {
            [os addObject: [c object]];
          }
          [delegate distributedView: self 
                      didSelectObjects: os];
          DESTROY(os);
        }
      }
      else if (clickCount > 1)
      {
        /* Open */
	if ([delegate respondsToSelector: @selector(distributedView:openObject:inNewWindow:)])
	{
	  [delegate distributedView: self openObject: [cell object] 
	                inNewWindow: modifier & NSControlKeyMask];
	}
      }
    }
    else
    {
      /* If there is no cell, remove all selected cells unless Shift is hold */
      if ((modifier & NSShiftKeyMask) == 0)
      {
        e = [selectedCells objectEnumerator];
        while ((c = [e nextObject]))
        {
	  [c setState: NSOffState];
        }
	[selectedCells removeAllObjects];
      }
    }
  }

  [self setNeedsDisplay: YES];
}

- (void) mouseDragged: (NSEvent *) event
{
  //int clickCount = [event clickCount]; // Error: complain wrong type.
  NSEventType type = [event type];
  //unsigned int modifier = [event modifierFlags];
  NSPoint location = [self convertPoint: [event locationInWindow] 
                               fromView: nil];
  OSDistributedCell *cell = [self _cellAtLocation: location];
  if (cell && (type == NSLeftMouseDragged))
  {
    if ([cell state] != NSOnState)
    {
      /* Cell is not selected. Select it */
      [cell setState: NSOnState];
      [selectedCells addObject: cell];
    }

    NSImage *image = [self _imageForDraggingSource];
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName: NSDragPboard];
    [pboard declareTypes: [NSArray arrayWithObject: NSFilenamesPboardType]
                   owner: nil];
    /* Build up indexes */
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    int i;
    NSArray *array = [self selectedCells];
    for (i = 0; i < [array count]; i++)
    {
      [indexes addIndex: [cells indexOfObject: [array objectAtIndex: i]]];
    }

    /* Ask data source to setup pasteboard.
       This method is only called once when drag starts.
       Therefore, it is safe to ask data source here. */
    if ([dataSource respondsToSelector: @selector(distributedView:writeObjectsWithIndexes:toPasteboard:)])
    {
      BOOL result = [dataSource distributedView: self writeObjectsWithIndexes: indexes toPasteboard: pboard];
      if (result == YES)
      {
        /* Drag start */
        [self dragImage: image 
                     at: location
                 offset: NSMakeSize(0, 0) /* Not used in Mac OS X 10.4 */
                  event: event
             pasteboard: pboard
                 source: self
              slideBack: YES];
      }
    }
  }
}

/* Drawing */

- (void) drawRect: (NSRect) frame
{
#if 0
  if ([self needsDisplay] == NO)
    return;
#endif

  [super drawRect: frame];

  [self _buildCells];
  [self _distributeCells];

  [self lockFocus];

  /* Draw background */
  //[[NSColor whilteColor] set];
  //[[NSColor controlBackgroundColor] set];
  //NSRectFill([self frame]);

  int i, count = [cells count];
  OSDistributedCell *cell = nil;
  NSRect rect = NSZeroRect;;
  for (i = 0; i < count; i++)
  {
    cell = [cells objectAtIndex: i];
    rect.origin = [cell origin];
    rect.size = [cell cellSize];
    [cell drawWithFrame: rect inView: self];
  }

  [self unlockFocus];
  [self setNeedsDisplay: NO];
}

- (BOOL) isFlipped
{
  return YES;
}

- (NSArray *) selectedCells
{
  return selectedCells;
}

- (OSDistributedCell *) selectedCell
{
  if ([selectedCells count])
  {
    return [selectedCells lastObject];
  }
  return nil;
}

- (void) setDelegate: (id) d
{
  ASSIGN(delegate, d);
}

- (id) delegate
{
  return delegate;
}

- (void) setDataSource: (id) ds
{
  ASSIGN(dataSource, ds);
}

- (id) dataSource
{
  return dataSource;
}


- (id) initWithFrame: (NSRect) rect
{
  self = [super initWithFrame: rect];
  cells = [[NSMutableArray alloc] init];
  selectedCells = [[NSMutableArray alloc] init];
  [self setNeedsDisplay: YES];
  [self registerForDraggedTypes: 
                        [NSArray arrayWithObject: NSFilenamesPboardType]];
  return self;
}

- (void) dealloc
{
  DESTROY(cells);
  DESTROY(selectedCells);
  DESTROY(delegate);
  DESTROY(dataSource);
  [super dealloc];
}

/* Dragging Source */
- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL) local
{
  /* We only support copy and move. 
     Deleting is equivalent to moving to trash can */
  if (local)
  {
    return (NSDragOperationCopy | NSDragOperationMove);
  }
  else 
  {
    /* GNUstep does not handle combination of drag operation across 
     * process due to the limitation of Xdnd. See GNUstep bug #18313. */
    return NSDragOperationAll;
  }
}

- (void) draggedImage: (NSImage *) image
              endedAt: (NSPoint) point
            deposited: (BOOL) flag
{
  // This one is deprecated in Mac OS X 10.4
  //NSLog(@"point %@, deposited %d", NSStringFromPoint(point), flag);
  /* We refresh ourself as drag source. */
  /* NOTE: there is no method to notify the source when dragging is done.
     Therefore, we solely depending on data source to refresh correctly */
  [self setNeedsDisplay: YES];

  /* Be sure the oldCellForDrop does not exist anymore ? */
}

- (void) draggedImage: (NSImage *) image
              endedAt: (NSPoint) point
            operation: (NSDragOperation) operation
{
  // But this one is not working in GNUstep
  NSLog(@"point %@, operation %d", NSStringFromPoint(point), operation);
}

/* Dragging Destination */
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
    if (mask & NSDragOperationCopy) 
    {
      return NSDragOperationCopy;
    }
  }
  return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
  NSDragOperation mask = [sender draggingSourceOperationMask];
  NSPoint point = [self convertPoint: [sender draggingLocation] fromView: nil];
  OSDistributedCell *cell = [self _cellAtLocation: point];
  if (cell)
  {
    if (oldCellForDrop && (oldCellForDrop != cell))
      [oldCellForDrop setDropTarget: NO];
    oldCellForDrop = cell;
    [cell setDropTarget: YES];
  }
  else
  {
    /* No cell under mouse */
    if (oldCellForDrop)
    {
      [oldCellForDrop setDropTarget: NO];
      oldCellForDrop = nil;
    }
  }
  [self setNeedsDisplay: YES];

  BOOL result = YES;
  if ([dataSource respondsToSelector: @selector(distributedView:validateDrop:onObject:)])
  {
    result = [dataSource distributedView: self
                            validateDrop: sender
                                onObject: [cell object]];
  }

  if (result == YES)
    return mask;

  /* We clean up here in case any of the furthur drag method 
     (-prepare..., -conclude...) is not called */
  if (oldCellForDrop)
  {
    [oldCellForDrop setDropTarget: NO];
    oldCellForDrop = nil;
  }
  [self setNeedsDisplay: YES];
  return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
  if (oldCellForDrop)
  {
    [oldCellForDrop setDropTarget: NO];
    oldCellForDrop = nil;
  }
  [self setNeedsDisplay: YES];
}

- (BOOL) prepareForDragOperation: (id <NSDraggingInfo>) sender
{
  /* We clean up here in case any of the furthur drag method 
     (-prepare..., -conclude...) is not called */
  if (oldCellForDrop)
  {
    [oldCellForDrop setDropTarget: NO];
    oldCellForDrop = nil;
  }
  [self setNeedsDisplay: YES];
  return YES;
}

- (BOOL) performDragOperation: (id <NSDraggingInfo>) sender
{
  BOOL success = NO;
  NSPoint point = [self convertPoint: [sender draggingLocation] fromView: nil];
  OSDistributedCell *cell = [self _cellAtLocation: point];
  id <OSObject> o = nil;
  if (cell)
    o = [cell object];
  if ([dataSource respondsToSelector: @selector(distributedView:acceptDrop:onObject:)])
  {
    success = [dataSource distributedView: self
                               acceptDrop: sender
                                 onObject: o];
  }
  success = NO;

  /* re-display as drag destination */
  [self setNeedsDisplay: YES];

  return success;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
}

@end

