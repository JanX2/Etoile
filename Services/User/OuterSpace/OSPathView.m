#import "OSPathView.h"
#import "OSPathCell.h"
#import <IconKit/IconKit.h>
#import <EtoileUI/NSImage+NiceScaling.h>

#define PAD 3

@implementation OSPathView
/* Private */
- (void) _buildPathCells
{
  [cells removeAllObjects];
  NSEnumerator *e = [[path componentsSeparatedByString: @"/"] objectEnumerator];
  NSString *component = nil;
  NSString *p = prefix;
  while ((component = [e nextObject]))
  {
    if ([component length] == 0)
      continue;
    OSPathCell *cell = [[OSPathCell alloc] initTextCell: component];
    p = [p stringByAppendingPathComponent: component];
    [cell setButtonType: NSToggleButton];
    [cell setBordered: NO];
    [cell setTitle: component];
    [cell setImagePosition: NSImageLeft];
    [cell setImage: [[IKIcon iconForFile: p] image]];
    [cell setTarget: self];
    [cell setAction: @selector(pathAction:)];
    [cells addObject: cell];
  }
  startIndex = 0;
}
   
/* End of Private */

- (void) pathAction: (id) sender
{
  if ([cells containsObject: sender])
  {
    NSRange range = NSMakeRange(0, [cells indexOfObject: sender]+1);
    NSEnumerator *e = [[cells subarrayWithRange: range] objectEnumerator];
    OSPathCell *cell = nil;
    NSString *p = prefix;
    while ((cell = [e nextObject]))
    {
      p = [p stringByAppendingPathComponent: [cell title]];
    }
    if (delegate && [delegate respondsToSelector: @selector(pathView:selectedPath:)])
    {
      [delegate pathView: self selectedPath: p];
    }
  }
}

- (void) buttonAction: (id) sender
{
  if (sender == left)
  {
    //NSLog(@"Left");
    if (startIndex > 0)
      startIndex--;
  }
  else if (sender == right)
  {
    //NSLog(@"Right");
    if (startIndex < [cells count]-1)
      startIndex++;
  }
  [self setNeedsDisplay: YES];
}

/* Override */
- (void) mouseDown: (NSEvent *) event
{
  NSPoint location = [self convertPoint: [event locationInWindow] fromView: nil];
  NSRect frame = [self frame];
  NSRect leftFrame = NSMakeRect(PAD, PAD, NSHeight(frame)-2*PAD, NSHeight(frame)-2*PAD);
  NSRect rightFrame = NSZeroRect;
  rightFrame.size = leftFrame.size;
  rightFrame.origin = NSMakePoint(NSWidth(frame)-PAD-rightFrame.size.width, PAD);
  if (NSMouseInRect(location, leftFrame, [self isFlipped]))
  {
    [left highlight: YES withFrame: leftFrame inView: self];
    BOOL result = [left trackMouse: event inRect: leftFrame
	                    ofView: self untilMouseUp: NO];
    [left highlight: NO withFrame: leftFrame inView: self];

    if (result == YES)
    {
      /* Mouse clicked */
      [[left target] performSelector: [left action] withObject: left];
      //NSLog(@"Left %d", result);
    }
  }
  else if (NSMouseInRect(location, rightFrame, [self isFlipped]))
  {
    [right highlight: YES withFrame: rightFrame inView: self];
    BOOL result = [right trackMouse: event inRect: rightFrame
	                    ofView: self untilMouseUp: NO];
    [right highlight: NO withFrame: rightFrame inView: self];
    if (result == YES)
    {
      /* Mouse clicked */
      //NSLog(@"Right %d", result);
      [[right target] performSelector: [right action] withObject: right];

    }
  }
  else
  {
    NSRect rect;
    NSPoint point;	
    point.x = NSMaxX(leftFrame)+PAD;
    point.y = leftFrame.origin.y;
    OSPathCell *cell = nil;
    int i;
    for (i = startIndex; i < [cells count]; i++)
    {
      cell = [cells objectAtIndex: i];
      NSSize size = [cell cellSize];
      rect.origin = point;
      rect.size.width = size.width;
      rect.size.height = leftFrame.size.height;
      if (startIndex != 0)
      {
	/* The first separator if it does not display from the beginning */
	rect.origin.x += NSWidth(leftFrame)+PAD;
      }
      if (NSMouseInRect(location, rect, [self isFlipped]))
      {
	[cell highlight: YES withFrame: rect inView: self];
	BOOL result = [cell trackMouse: event inRect: rect
	                        ofView: self untilMouseUp: NO];
	[cell highlight: NO withFrame: rect inView: self];
	if (result)
	{
	  //NSLog(@"%@ (%@)", cell, [cell title]);
	  [[cell target] performSelector: [cell action] withObject: cell];
 	  /* Found cell. Break the loop, otherwise it keep testing the rest. */
	  break;
	}
      }
      point.x += NSWidth(rect)+PAD;
      /* Consider the separator */
      point.x += (NSWidth(leftFrame)+PAD);
    }
  }
}

- (void) drawRect: (NSRect) f
{
  //NSLog(@"OSPathView drawRect");
  NSRect rect;
  NSPoint point;
  NSRect frame = [self frame];
  NSSize square = NSMakeSize(NSHeight(frame)-2*PAD, NSHeight(frame)-2*PAD);
	
  [super drawRect: f];
  [self lockFocus];
  //[[NSColor controlBackgroundColor] set];
  [[NSColor lightGrayColor] set];
  NSRectFill([self bounds]);
	
  /* We draw left button */
  rect = NSMakeRect(PAD, PAD, square.width, square.height);
  [left drawWithFrame: rect inView: self];
	
  /* We shouldn't rebuild cells here. 
     It only need to be rebuilt when path changed */
  //[self _buildPathCells];
	
  point.x = NSMaxX(rect)+PAD;
  point.y = rect.origin.y;
	
  if (startIndex != 0)
  {
    rect.origin = point;
    rect.size = square;
    [separator drawWithFrame: rect inView: self];
    point.x += (NSWidth(rect)+PAD);
  }
	
  /* draw cells */
  int i, count = [cells count];
  for (i = startIndex; i < count; i++)
  {
    BOOL drawCell = NO;
    BOOL drawSeparator = NO;
    OSPathCell *cell = [cells objectAtIndex: i];
    /* We need to shrink button image first */
    if (NSEqualSizes([[cell image] size], square) == NO)
    {
      NSImage *im = [[cell image] scaledImageToFitSize: square];
      [cell setImage: im];
    }
    NSSize size = [cell cellSize];
    rect.origin = point;
    rect.size.width = size.width;
    rect.size.height = NSHeight(frame)-2*PAD;
    /* If it is out of sight, don't draw it */
    int max = NSMaxX(frame)-(PAD+square.width+PAD)*2;
    if (i < count-1)
    {
      /* This is not the last one, we have to be able to draw the separator
         to indicate it is not the last one */
      if ((NSMaxX(rect)+PAD+square.width) < max)
      {
	drawCell = YES;
	drawSeparator = YES;
      }
      else
      {
	break;
      }
    }
    else
    {
      /* This is the last one, we only need space for cell, not separator. */
      if (NSMaxX(rect) < max)
      {
	drawCell = YES;
      }
      else
      {
	break;
      }
    }
		
    if (drawCell)
    {
      [cell drawWithFrame: rect inView: self];
      point.x += NSWidth(rect)+PAD;
    }
			
    if (drawSeparator)
    {
      rect.origin = point;
      rect.size = square;
      [separator drawWithFrame: rect inView: self];
      point.x += (NSWidth(rect)+PAD);
    }
  }
	
  /* We draw left button */
  rect = NSZeroRect;
  rect.size = square;
  rect.origin = NSMakePoint(NSWidth(frame)-PAD-rect.size.width, PAD);
  [right drawWithFrame: rect inView: self];
  [self unlockFocus];
}

- (id) initWithFrame: (NSRect) frame
{
  self = [super initWithFrame: frame];
	
  left = [[NSButtonCell alloc] initImageCell: [NSImage imageNamed: @"common_ArrowLeft"]];
  [left setButtonType: NSToggleButton];
  [left setBordered: NO];
  [left setTarget: self];
  [left setAction: @selector(buttonAction:)];
	
  right = [[NSButtonCell alloc] initImageCell: [NSImage imageNamed: @"common_ArrowRight"]];
  [right setButtonType: NSToggleButton];
  [right setBordered: NO];
  [right setTarget: self];
  [right setAction: @selector(buttonAction:)];
	
  separator = [[NSImageCell alloc] initImageCell: [NSImage imageNamed: @"OSRightArrow"]];
  [separator setImageAlignment: NSImageAlignCenter];
  [separator setImageScaling: NSScaleNone];

  cells = [[NSMutableArray alloc] init];
  startIndex = NSNotFound;
	
  return self;
}

- (void) dealloc
{
  DESTROY(cells);
  DESTROY(prefix);
  DESTROY(path);
  DESTROY(left);
  DESTROY(right);
  DESTROY(separator);
  DESTROY(delegate);
  [super dealloc];
}

/* Accessories */
- (NSString *) prefix
{
  return prefix;
}

- (void) setPrefix: (NSString *) p
{
  ASSIGN(prefix, [p stringByStandardizingPath]);
  [self _buildPathCells];
}

- (NSString *) path
{
  return path;
}

- (void) setPath: (NSString *) p
{
  ASSIGN(path, p);
  [self _buildPathCells];
  [self setNeedsDisplay: YES]; /* Redraw */
}

- (NSString *) absolutePath
{
  return [prefix stringByAppendingPathComponent: path];
}


- (void) setDelegate: (id) d
{
  ASSIGN(delegate, d);
}

- (id) delegate
{
  return delegate;
}

@end
