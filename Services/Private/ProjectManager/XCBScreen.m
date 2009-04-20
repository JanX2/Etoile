#import "XCBScreen.h"
#import "XCBWindow.h"

#import <EtoileFoundation/EtoileFoundation.h>

@implementation XCBScreen 
- (id) initWithXCBScreen: (xcb_screen_t*)aScreen
{
	SELFINIT;
	screen = *aScreen;
	root = [XCBWindow windowWithXCBWindow: screen.root];
	return self;
}
+ (XCBScreen*) screenWithXCBScreen: (xcb_screen_t*)aScreen
{
	return [[[self alloc] initWithXCBScreen: aScreen] autorelease];
}
- (void) dealloc
{
	[root release];
	[super dealloc];
}
- (XCBWindow*) rootWindow
{
	return root;
}
- (xcb_screen_t*)screenInfo
{
	return &screen;
}
@end
