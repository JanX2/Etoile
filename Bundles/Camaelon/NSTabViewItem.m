#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "GSDrawFunctions.h"

@implementation NSTabViewItem (theme)

- (void)drawLabel:(BOOL)shouldTruncateLabel
           inRect:(NSRect)tabRect
{
  NSGraphicsContext     *ctxt = GSCurrentContext();
  NSRect lRect; 
  NSRect fRect;
  NSDictionary *attr;
  NSString *string;

  if (shouldTruncateLabel)
    {
      string = [self _truncatedLabel];
    }
  else 
    { 
        string = _label;
    }
    
  _rect = tabRect;
    
  DPSgsave(ctxt);
  fRect = tabRect;
  NSImage* img = [NSImage imageNamed: @"Tabs/Tabs-panebar-fill.tiff"];
  fRect.origin.y -= [img size].height;

  if (_state == NSSelectedTab)
    {
     // fRect.size.height += 2;
     // [[NSColor controlBackgroundColor] set];
     // NSRectFill(fRect);
     [GSDrawFunctions drawTopTabFill: fRect selected: YES on: nil];
    }
  else if (_state == NSBackgroundTab)
    {
     // [[NSColor controlBackgroundColor] set];
     // NSRectFill(fRect);
     [GSDrawFunctions drawTopTabFill: fRect selected: NO on: nil];
    }
  else
    {
      [[NSColor controlBackgroundColor] set];
    }

  attr = [[NSDictionary alloc] initWithObjectsAndKeys:
                               [_tabview font], NSFontAttributeName,
                               [NSColor blackColor], NSForegroundColorAttributeName,
                               nil];

  NSSize s = [self sizeOfLabel: NO];

  lRect = tabRect;
  lRect.origin.y = fRect.origin.y - (fRect.size.height - s.height)/2.0;
  [string drawInRect: lRect withAttributes: attr];
  RELEASE(attr);

  DPSgrestore(ctxt);
}


@end
