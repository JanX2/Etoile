#import <Foundation/Foundation.h>
#import <xcb/xcb.h>

@interface XCBAtomCache : NSObject {
	NSMutableDictionary *requestedAtoms;
	NSMutableDictionary *fetchedAtoms;
}
+ (XCBAtomCache*)sharedInstance;
- (void)cacheAtom: (NSString*)aString;
- (xcb_atom_t)atomNamed: (NSString*)aString;
@end
