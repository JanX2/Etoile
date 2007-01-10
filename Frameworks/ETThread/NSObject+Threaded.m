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
    [ETThread detatchNewThreadSelector:@selector(runloop:)
							  toTarget:proxy
							withObject:nil];
    return proxy;
}

- (id) invokeInNewThread:(NSInvocation*)anInvocation
{
	[anInvocation retain];
	[anInvocation retainArguments];
	[anInvocation setTarget:self];
	struct ETThreadedInvocationInitialiser * init = 
		malloc(sizeof(struct ETThreadedInvocationInitialiser));
	init->invocation = anInvocation;
	init->retVal = [[[[ETThreadProxyReturn alloc] init] retain] autorelease];
	pthread_t thread;
	pthread_create(&thread, NULL, threadedInvocationTrampoline, init);
	pthread_detach(thread);
	return init->retVal;
}
@end
