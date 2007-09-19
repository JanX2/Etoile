#import "NSObject+Threaded.h"
#import "ETThread.h"
#import "ETThreadedObject.h"
#import "ETThreadProxyReturn.h"

struct ETThreadedInvocationInitialiser
{
	NSInvocation * invocation;
	ETThreadProxyReturn * retVal;
};

void * threadedInvocationTrampoline(void* initialiser)
{
	struct ETThreadedInvocationInitialiser * init = initialiser;
	id pool = [[NSAutoreleasePool alloc] init];
	[init->invocation invoke];
	id retVal;
	[init->invocation getReturnValue:&retVal];
	[init->retVal setProxyObject:retVal];
	[init->invocation release];
	[init->retVal release];
	free(init);
	[pool release];
	return NULL;
}

@implementation NSObject (Threaded)
+ (id) threadedNew
{
    id proxy = [[ETThreadedObject alloc] initWithClass:[self class]];
    [ETThread detachNewThreadSelector:@selector(runloop:)
							  toTarget:proxy
							withObject:nil];
    return proxy;
}

- (id) inNewThread
{
		return [[[ETThreadedObject alloc] initWithObject:self] autorelease];
}
@end
