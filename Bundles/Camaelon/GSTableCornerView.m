#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "GSDrawFunctions.h"

@interface GSTableCornerView : NSView 
{} 
@end

@implementation GSTableCornerView (theme)
  
- (void) drawRect: (NSRect) cellFrame
{ 
  [GSDrawFunctions drawTableHeaderInRect: cellFrame];
}

@end

