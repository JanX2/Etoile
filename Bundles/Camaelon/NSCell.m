#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

@implementation NSCell (theme)

- (NSColor*) textColor
{
  if (_cell.is_disabled)
      return [NSColor disabledControlTextColor];
  else if (_cell.is_highlighted || _cell.state)
	  return [NSColor selectedRowTextColor];
  else
	  return [NSColor controlTextColor];
}
@end
