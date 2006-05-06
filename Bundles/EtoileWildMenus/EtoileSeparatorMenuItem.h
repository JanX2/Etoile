
#import <AppKit/NSMenuItem.h>

/*
 * This class serves a rather dummy function. If the underlying
 * menu item cell sees that it's associated menu item is a subclass
 * of this, it will instead act as a separator item.
 */
@interface EtoileSeparatorMenuItem : NSMenuItem
@end
