
#import "NSMenuItem+Hackery.h"

#import <AppKit/NSMenuItemCell.h>
#import "EtoileSeparatorMenuItem.h"

@implementation NSMenuItem (EtoileMenusHackery)

+ (id <NSMenuItem>) separatorItem
{
  return AUTORELEASE([EtoileSeparatorMenuItem new]);
}

@end
