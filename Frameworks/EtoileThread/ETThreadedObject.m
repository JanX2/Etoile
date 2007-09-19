#import "ETThreadedObject.h"
#import "ETThreadProxyReturn.h"
#include <sched.h>

@implementation ETThreadedObject
- (id) init
{
	pthread_cond_init(&conditionVariable, NULL);
	pthread_mutex_init(&mutex, NULL);
	invocations = [[NSMutableArray alloc] init];
	returns = [[NSMutableArray alloc] init];
	return self;
}
- (id) initWithClass:(Class) aClass
{
	if(nil == (self = [self init]))
	{
		return nil;
	}
	object = [[aClass alloc] init];
	return self;
}
- (id) initWithObject:(id) anObject
{
	if(nil == (self = [self init]))
	{
		return nil;
	}
	object = [anObject retain];
	return self;
}
- (void) dealloc
{
	/* Instruct worker thread to exit */
	pthread_mutex_lock(&mutex);
	terminate = YES;
	/* Wait for worker thread to let us know which thread object belongs to it*/
	while(thread == nil)
	{
		pthread_cond_signal(&conditionVariable);
		pthread_mutex_unlock(&mutex);
		pthread_mutex_lock(&mutex);
	}
	pthread_cond_signal(&conditionVariable);
	pthread_mutex_unlock(&mutex);
	/* Wait for worker thread to terminate */
	[thread waitForTermination];
	[thread release];
	/* Destroy synchronisation objects */
	pthread_cond_destroy(&conditionVariable);
	pthread_mutex_destroy(&mutex);
	/* Clean up */
	[invocations release];
	[super dealloc];
}

- (void) runloop:(id)sender
{
	thread = [[ETThread currentThread] retain];
	while (object)
	{
		pthread_mutex_lock(&mutex);
		/* If there are no messages waiting, sleep until there are */
		while ([invocations count] == 0)
		{
			if (terminate)
			{
				[object release];
				return;
			}
			pthread_cond_wait(&conditionVariable, &mutex);
		}
		NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
		/* Take the first invocation from the queue */
		NSInvocation * anInvocation = [[invocations objectAtIndex:0] retain];
		[invocations removeObjectAtIndex:0];
		/* Now that we've got the message, unlock the queue */
		pthread_mutex_unlock(&mutex);
		
		BOOL concreteType = NO;	
		ETThreadProxyReturn * retVal = nil;
		if([[anInvocation methodSignature] methodReturnType][0] == '@')
		{
			retVal = [returns objectAtIndex:0];
			[returns removeObjectAtIndex:0];
			//TODO: Implement auto-boxing for non-object returns
		}
		else
		{
			concreteType = YES;
		}

		[anInvocation invokeWithTarget:object];

		if (concreteType == YES)
		{
			[anInvocation release];
		}

		if(retVal != nil)
		{
			id realReturn;
			[anInvocation getReturnValue:&realReturn];
			[retVal setProxyObject:realReturn];
			/*
			  Proxy return object is created with a retain count of 2 and an autorelease
			  count of 1 in the main thread.  This will set it to a retain count of 1
			  and an autorelease count of 1 if it has not been used, or dealloc it if it
			  has
			*/
			//[retVal release];
		}

		[anInvocation release];
		[pool release];
	}
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	return [object methodSignatureForSelector:aSelector];
}

- (id) returnProxy
{
	return proxy;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	BOOL concreteType = NO;
	int rc = 0;

	if(![anInvocation argumentsRetained])
	{
		[anInvocation retainArguments];
	}

	if([[anInvocation methodSignature] methodReturnType][0] == '@')
	{
		ETThreadProxyReturn * retVal = [[[ETThreadProxyReturn alloc] init] autorelease];
		[returns addObject:retVal];
		proxy = retVal;
		/*
		  This is a hack to force the invocation to stop blocking the caller.
		*/
		SEL selector = [anInvocation selector];
		[anInvocation setSelector:@selector(returnProxy)];
		[anInvocation invokeWithTarget:self];
		[anInvocation setSelector:selector];
	}
	else
	{
		/*
		 * This is a hack.. if the method returns a concrete type (eg not an
		 * object) the result is immediately assigned as soon a
		 * forwardInvocation: ends.  As the invocation is not yet invoked, that
		 * means we get default values instead of the correct returned value
		 * (eg, with a method returning an int, say 42, the actual value
		 * returned will be 0) But as we can't call the invocation ourself
		 * (that would break the invocations order) we need to wait until the
		 * runloop invoke it. We could use a condition variable to signal that
		 * the invocation is ready, but a faster way is to poll until the
		 * invocation is done (no context switch that way).  There doesn't seem
		 * to be a method returning the invocation status, therefore we simply
		 * increment the retain count before adding the invocation to the
		 * runloop.  In the runloop we decrement the retain count once the
		 * invocation is invoked, and we just wait until the retain count
		 * equals the original count.
		 */
		rc = [anInvocation retainCount];
		[anInvocation retain];
		concreteType = YES;
	}

	pthread_mutex_lock(&mutex);
	[invocations addObject:anInvocation];
	pthread_cond_signal(&conditionVariable);
	pthread_mutex_unlock(&mutex);

	if (concreteType)
	{
		while ([anInvocation retainCount] > rc) 
		{
			// do nothing... just poll...
			sched_yield();
		}
	}
}
@end
