#include "CLCache.h"

@implementation CLCache
CLCache* CLCacheSingleton;
+ (id) cache {
	if (CLCacheSingleton== nil)
	{
		CLCacheSingleton = [CLCache new];
	}
	return CLCacheSingleton;
}
- (id) init {
	self = [super init];
	cache = [NSMutableDictionary new];
	return self;
}
- (NSImage*) imageNamed: (NSString*) name {
	return [cache objectForKey: name];
}
- (void) setImage: (NSImage*) image named: (NSString*) name {
	[cache setObject: image forKey: name];	
}
@end

