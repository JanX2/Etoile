#import <Foundation/Foundation.h>
#import "XCBConnection.h"

@interface PMConnectionDelegate : NSObject {
	NSMutableSet *documentWindows;
	NSMutableSet *panelWindows;
	NSMutableDictionary *decorationWindows;
	NSMutableArray *compositeWindows;
	NSMutableDictionary *compositers;
	NSMutableDictionary *decoratedWindows;
}
@end

PMConnectionDelegate *PMApp;
