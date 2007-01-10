#import "ETThreadProxyReturn.h"

@implementation ETThreadProxyReturn
- (id) init
{
	object = nil;
	pthread_cond_init(&conditionVariable, NULL);
	pthread_mutex_init(&mutex, NULL);
	return self;
}

- (void) dealloc
{
	pthread_cond_destroy(&conditionVariable);
	pthread_mutex_destroy(&mutex);
	[object release];
	[super dealloc];
}

- (void) setProxyObject:(id)anObject
{
	pthread_mutex_lock(&mutex);
	object = [anObject retain];
	pthread_cond_signal(&conditionVariable);
	pthread_mutex_unlock(&mutex);
}

- (id) value
{
	if(object == nil)
	{
		pthread_mutex_lock(&mutex);
		if(nil == object)
		{
			pthread_cond_wait(&conditionVariable, &mutex);
		}
		pthread_mutex_unlock(&mutex);
	}
	return object;
}
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	//If we haven't yet got the object, then block until we have, otherwise do this quickly
	if(object == nil)
	{
		[self value];
	}
	return [object methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	pthread_mutex_lock(&mutex);
	if(nil == object)
	{
		pthread_cond_wait(&conditionVariable, &mutex);
	}
	pthread_mutex_unlock(&mutex);
	[anInvocation invokeWithTarget:object];
}
@end
