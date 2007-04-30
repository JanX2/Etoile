#import "OSDistributedCell.h"

#define TEXT_HEIGHT 25
#define PAD 2

@implementation OSDistributedCell

- (void) setObject: (id <OSObject>) o
{
  ASSIGN(object, o);

  /* Scale image up to 4 times (2x2) of CELL_SIZE  */
  NSImage *preview = [object preview];
  NSSize size = [preview size];
  float f = ((float)size.width) / size.height;
  float w, h;
  float max_h = CELL_SIZE*2-TEXT_HEIGHT-PAD*3;
  float max_w = CELL_SIZE*2-PAD*2;
  if (size.height > size.width) 
  {
    h = (size.height < max_h) ? size.height : max_h;
    w = f * h;
  }
  else 
  {
    w = (size.width < max_w) ? size.width : max_w;
    h = w / f;
  }
  if ((w < 2) || (h < 2))
    NSLog(@"Error: (w, h) = (%f %f)", w, h);
  previewSize = NSMakeSize(w,h);
  [preview setSize: previewSize];
  [self setImage: preview];

  /* Get title size */
  [self setStringValue: [object name]];
  NSMutableAttributedString *as = [[NSMutableAttributedString alloc] initWithString: [object name]];
  [as addAttribute: NSFontAttributeName
             value: [self font] 
             range: NSMakeRange(0, [as length])];
  ASSIGNCOPY(title, as);
  RELEASE(as);
  textSize = [title size];
}

- (id <OSObject>) object
{
  return object;
}

- (void) setOrigin: (NSPoint) point
{
  origin = point;
}

- (NSPoint) origin
{
  return origin;
}

- (void) setDropTarget: (BOOL) flag
{
  isDropTarget = flag;
}

- (BOOL) isDropTarget
{
  return isDropTarget;
}

/* Override */
- (NSSize) cellSize
{
  NSSize size = NSZeroSize;
  size.width = ((textSize.width+2*PAD) < previewSize.width) ?
                              previewSize.width : (textSize.width+2*PAD);
  size.height = previewSize.height + textSize.height + 3*PAD;
  return size;
}

- (void) drawInteriorWithFrame: (NSRect) cellFrame 
                        inView: (NSView *) controlView
{
  BOOL flipped = [controlView isFlipped];
//  NSFrameRect(cellFrame);

  /* Draw background is selected (NSOnState) */
  if ([self state] == NSOnState)
  {
    [[NSColor controlBackgroundColor] set];
    //[[NSColor yellowColor] set];
    NSRectFill(cellFrame);
  }
  if ([self isDropTarget])
  {
    [[NSColor yellowColor] set];
    NSRectFill(cellFrame);
  }

  /* Draw Text */
  NSPoint p;
  p = cellFrame.origin;
  /* Put text in the center */
  p.x = cellFrame.origin.x+(cellFrame.size.width-textSize.width)/2;
  if (flipped == YES)
  {
    p.y = NSMaxY(cellFrame)-[title size].height-PAD;
  }
  [title drawAtPoint: p];

  /* Calculate size */
  NSImage *image = [object preview];
  p.x = cellFrame.origin.x+(cellFrame.size.width-previewSize.width)/2;
  if (flipped)
  {
    p.y += PAD;
    [image setFlipped: YES];
  }
  if (image) 
  {
    [image compositeToPoint: p 
           operation: NSCompositeSourceOver]; 
  }
  else
  {
//    NSLog(@"No image");
  }
}

- (id) init
{
  self = [super init];
  [self setSelectable: YES];
  origin = NSZeroPoint;
  return self;
}

- (void) dealloc
{
  DESTROY(object);
  [super dealloc];
}

@end

