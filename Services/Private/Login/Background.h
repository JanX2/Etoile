#import <AppKit/AppKit.h>

@interface Background : NSObject
{
	id view;
}
- (void) set;
+ (Background*) background;
- (void) redraw;
- (void) setNeedsDisplayInRect: (NSRect) aRect;

@end
