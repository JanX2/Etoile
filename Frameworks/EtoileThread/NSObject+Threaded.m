#import "NSObject+Threaded.h"
#import "EtoileThread.h"
#import "EtoileThreadedObject.h"
#import "EtoileThreadProxyReturn.h"

struct EtoileThreadedInvocationInitialiser
{
	NSInvocation * invocation;
	EtoileThreadProxyReturn * retVal;
};

void * threadedInvocationTrampoline(void* initialiser)
{
	struct EtoileThreadedInvocationInitialiser * init = initialiser;
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
    id proxy = [[EtoileThreadedObject alloc] initWithClass:[self class]];
    [EtoileThread detachNewThreadSelector:@selector(runloop:)
							  toTarget:proxy
							withObject:nil];
    return proxy;
}

- (id) inNewThread
{
		return [[[EtoileThreadedObject alloc] initWithObject:self] autorelease];
}
@end
