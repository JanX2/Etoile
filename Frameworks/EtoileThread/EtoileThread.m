#import "EtoileThread.h"

struct EtoileThreadInitialiser
{
	id object;
	SEL selector;
	id target;
	NSAutoreleasePool * pool;
	EtoileThread * thread;
};

static pthread_key_t threadObjectKey;

void cleanup(void * initialiser)
{
	struct EtoileThreadInitialiser * init = initialiser;
	[init->thread release];
	[init->pool release];
	free(init);
}

/* Thread creation trampoline */
void * threadStart(void* initialiser)
{
	[NSAutoreleasePool new];
	struct EtoileThreadInitialiser * init = initialiser;
	pthread_setspecific(threadObjectKey, init->thread);
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	init->pool = pool;
	/*
	   This is 100% broken on Darwin.  These #defines can be removed if Apple
	   ever implements a version of pthread_cleanup_push that actually conforms
	   to the specification (i.e. does something useful, instead of requiring
	   cleanup functions to be popped as soon as they are pushed).
	*/
#ifndef __APPLE__
	pthread_cleanup_push(cleanup, initialiser);
#endif
	id result = [init->target performSelector:init->selector 
								   withObject:init->object];
	/*
	  This stuff should all be done by the pthread cleanup routine, but this is
	  currently broken on OS X.  This means that threads exited with 
	  -exitWithValue will leak memory on OS X.
	*/
#ifdef __APPLE__
	cleanup(init);
#endif
	return result;
}

@implementation EtoileThread

+ (void) initialize
{
	pthread_key_create(&threadObjectKey, NULL);
}

+ (id) detatchNewThreadSelector:(SEL)aSelector toTarget:(id)aTarget withObject:(id)anArgument
{
	EtoileThread * thread = [[EtoileThread alloc] init];
	if(thread == nil)
	{
		return nil;
	}
	struct EtoileThreadInitialiser * threadArgs = 
		malloc(sizeof(struct EtoileThreadInitialiser));
	threadArgs->object = anArgument;
	threadArgs->selector = aSelector;
	threadArgs->thread = thread;
	threadArgs->target = aTarget;
	pthread_create(&thread->thread, NULL, threadStart, threadArgs);
	return thread;
}

+ (EtoileThread*) currentThread
{
	return (EtoileThread*)pthread_getspecific(threadObjectKey);
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
	/* If no one has a reference to this object, don't keep the return value around */
	//NOTE: It might be worth catching the return value and releasing it to prevent
	//leaking.
	pthread_detach(thread);
	[super dealloc];
}
@end
