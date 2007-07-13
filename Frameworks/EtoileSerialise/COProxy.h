#import <Foundation/Foundation.h>

@interface COProxy : NSProxy {
	id object;
	int version;
	NSURL * baseURL;
	Class storageBackend;
}

@end
