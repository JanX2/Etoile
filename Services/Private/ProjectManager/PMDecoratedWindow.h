#import "XCBWindow.h"

@interface PMDecoratedWindow : NSObject {
	XCBWindow *window;
	XCBWindow *decorationWindow;
}
+ (PMDecoratedWindow*)windowDecoratingWindow: (XCBWindow*)win;
- (XCBWindow*)decorationWindow;
- (void)mapDecoratedWindow;
@end
