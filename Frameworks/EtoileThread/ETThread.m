#import "ETThread.h"

struct ETThreadInitialiser
{
	id object;
	SEL selector;
	id target;
	ETThread * thread;
};

static pthread_key_t threadObjectKey;

/* Thread creation trampoline */
void * threadStart(void* initialiser)
{
#ifdef GNUSTEP
	GSRegisterCurrentThread ();
#endif
	[NSAutoreleasePool new];
	struct ETThreadInitialiser * init = initialiser;
	id object = init->object;
	id target = init->target;
	SEL selector = init->selector;
	ETThread * thread = init->thread;
	free(init);
	pthread_setspecific(threadObjectKey, init->thread);
	thread->pool = [[NSAutoreleasePool alloc] init];
	id result = [init->target performSelector:selector 
								   withObject:object];
	//NOTE: Not reached if exitWithValue: is called
	[thread->pool release];
	[thread release];
	return result;
}

@implementation ETThread

+ (void) initialize
{
	pthread_key_create(&threadObjectKey, NULL);
}

+ (id) detachNewThreadSelector:(SEL)aSelector toTarget:(id)aTarget withObject:(id)anArgument
{
	ETThread * thread = [[ETThread alloc] init];
	if(thread == nil)
	{
		return nil;
	}
	struct ETThreadInitialiser * threadArgs = 
		malloc(sizeof(struct ETThreadInitialiser));
	threadArgs->object = anArgument;
	threadArgs->selector = aSelector;
	threadArgs->thread = thread;
	threadArgs->target = aTarget;
	pthread_create(&thread->thread, NULL, threadStart, threadArgs);
	return thread;
}

+ (ETThread*) currentThread
{
	return (ETThread*)pthread_getspecific(threadObjectKey);
}

- (id) waitForTermination
{
	void * retVal = nil;
	pthread_join(thread, &retVal);
	return (id)retVal;
}

- (BOOL) isCurrentThread
{
	if(pthread_equal(pthread_self(), thread) == 0)
	{
		return YES;
	}
	return NO;
}

- (void) exitWithValue:(id)aValue
{
	if([self isCurrentThread])
	{
		[pool release];
		[self release];
		pthread_exit(aValue);
	}
}

/* This shouldn't normally be used, since it will normally leak memory */
- (void) kill
{
	pthread_cancel(thread);
}

- (void) dealloc
{
	/* If no one has a reference to this object, don't keep the return value
	 * around */
	//NOTE: It might be worth catching the return value and releasing it to
	//prevent leaking.
	pthread_detach(thread);
	[super dealloc];
}
@end
