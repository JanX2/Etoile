#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

@interface GSBrowserMatrix : NSMatrix
{
}
- (void) _drawCellAtRow: (int) row column: (int) column;
@end
