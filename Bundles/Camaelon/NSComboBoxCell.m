#include "GSDrawFunctions.h"

@interface NSComboBoxCell (theme)
@end

@implementation NSComboBoxCell (theme)

- (void) _loadButtonCell
{
  _buttonCell = [[NSButtonCell alloc] initImageCell:
                    [NSImage imageNamed: @"NSComboArrow"]];
  [_buttonCell setImagePosition: NSImageOnly];
  [_buttonCell setButtonType: NSMomentaryPushButton];
  [_buttonCell setHighlightsBy: NSPushInCellMask];
  [_buttonCell setBordered: YES];
  [_buttonCell setTarget: self];
  [_buttonCell setAction: @selector(_didClickWithinButton:)];
  [_buttonCell setBezelStyle: NSShadowlessSquareBezelStyle];
}

@end
