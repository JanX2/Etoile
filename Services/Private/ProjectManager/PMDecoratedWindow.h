#import "XCBWindow.h"

@interface PMDecoratedWindow : NSObject {
	XCBWindow *window;
	XCBWindow *decorationWindow;
	BOOL ignoreUnmap;
}
+ (PMDecoratedWindow*)windowDecoratingWindow: (XCBWindow*)win;
- (XCBWindow*)decorationWindow;
- (void)mapDecoratedWindow;
@end
