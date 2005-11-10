#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "GraphicToolbox.h"
#include "GSDrawFunctions.h"
#include "GSWindowDecorationView.h"

@interface GSWindowDecorationView (theme)
@end

@implementation GSWindowDecorationView (theme)
- (void) drawRect: (NSRect)rect
{
  if (NSIntersectsRect(rect, contentRect))
    {
      [THEME drawWindowBackground: rect on: self];
    }
}
@end
