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

- (NSImage*) imageNamed: (NSString*) name withSize: (NSSize) size {
	NSString* key = [NSString stringWithFormat: @"%@-%.0fx%.0f", name, size.width, size.height];
	return [cache objectForKey: key];
}

- (void) setImage: (NSImage*) image named: (NSString*) name {
	NSString* key = [NSString stringWithFormat: @"%@-%.0fx%.0f", name, [image size].width, [image size].height];
	[cache setObject: image forKey: key];	
}
@end

