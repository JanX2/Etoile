#import <Foundation/Foundation.h>

@interface COProxy : NSProxy {
	id object;
	int version;
	NSURL * baseURL;
	id serialiser;
	id backend;
}
- (id) initWithObject:(id)anObject
           serialiser:(id)aSerialiser;
@end
