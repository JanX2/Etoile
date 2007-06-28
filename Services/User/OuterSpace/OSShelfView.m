#import "OSShelfView.h"
#import "OSShelfCell.h"

#define SEPARATOR_WIDTH 2
#define PAD 5

@implementation OSShelfView
/* Private */
- (OSShelfCell *) cellWithObject: (id) object
{
  OSShelfCell *cell = [[OSShelfCell alloc] initTextCell: @""];
  [cell setObject: object];
  [cell setBordered: NO];
  [cell setImagePosition: NSImageAbove];
  return AUTORELEASE(cell);
}

/* End of private */
- (void) mouseDown: (NSEvent *) event
{
  NSPoint point = NSMakePoint(PAD, PAD);
  NSRect frame = [self frame];
  NSRect rect = NSInsetRect(frame, PAD, PAD);
  int i;
  for(i = 0; i < [cells count]; i++)
  {
    OSShelfCell *cell = [cells objectAtIndex: i];
    rect.origin = point;
    if ([[cell object] isKindOfClass: [NSNull class]])
    {
      rect.size.width = SEPARATOR_WIDTH;
      /* Do nothing for seperator */
    }
    else
    {
      /* Must be OSObject */
      rect.size.width = [cell cellSize].width;
      [cell highlight: YES withFrame: rect inView: self];
      BOOL result = [cell trackMouse: event inRect:rect 
                              ofView: self untilMouseUp: NO];
      [cell highlight: NO withFrame: rect inView: self];
      if (result == YES)
      {
	/* Button clicked */
	if (delegate && 
	    [delegate respondsToSelector: @selector(shelfView:objectClicked:)])
	{
	  [delegate shelfView: self objectClicked: [cell object]];
	}
	break;
      }
    }
    point.x += (rect.size.width+PAD);
  }
}

- (void) drawRect: (NSRect) f
{
  [super drawRect: f];

  NSPoint point = NSMakePoint(PAD, PAD);
  NSRect frame = [self frame];
  NSRect rect = NSInsetRect(frame, PAD, PAD);
  int i;
  for(i = 0; i < [cells count]; i++)
  {
    OSShelfCell *cell = [cells objectAtIndex: i];
    rect.origin = point;
    if ([[cell object] isKindOfClass: [NSNull class]])
    {
      rect.size.width = SEPARATOR_WIDTH;
      [[NSColor darkGrayColor] set];
      NSRectFill(NSInsetRect(rect, 0, PAD));
    }
    else
    {
      /* Must be OSObject */
      rect.size.width = [cell cellSize].width;
      [cell drawWithFrame: rect inView: self];
    }
    point.x += (rect.size.width+PAD);
  }
}

- (int) numberOfObjects
{
  return [cells count];
}

- (void) addObject: (id) object
{
  [cells addObject: [self cellWithObject: object]];
}

- (void) insertObject: (id) object atIndex: (int) index
{
  [cells insertObject: [self cellWithObject: object] atIndex: index];
}

- (void) removeObjectAtIndex: (int) index
{
  [cells removeObjectAtIndex: index];
}

- (id) objectAtIndex: (int) index
{
  return [cells objectAtIndex: index];
}

- (id) initWithFrame: (NSRect) frame
{
  self = [super initWithFrame: frame];
  cells = [[NSMutableArray alloc] init];
  return self;
}

- (void) dealloc
{
  DESTROY(cells);
  DESTROY(delegate);
  [super dealloc];
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

