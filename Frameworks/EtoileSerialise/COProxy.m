#import "COProxy.h"
#import "ETSerialiser.h"

static const int FULL_SAVE_INTERVAL = 100;

@implementation COProxy 
- (id) initWithObject:(id)anObject
           serialiser:(id)aSerialiser
{
	object = [anObject retain];
	serialiser = [aSerialiser retain];
	[serialiser serialiseObject:object withName:"BaseVersion"];
	return self;
}
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	    return [object methodSignatureForSelector:aSelector];
}
- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	version = [serialiser newVersion];
	/* Periodically save a full copy */
	if(version % FULL_SAVE_INTERVAL == 0)
	{
		[anInvocation setTarget:object];
		[anInvocation invoke];
		[serialiser serialiseObject:object withName:"FullSave"];
	}
	else
	{
		[anInvocation setTarget:nil];
		[serialiser serialiseObject:anInvocation withName:"Delta"];
		[anInvocation setTarget:object];
		[anInvocation invoke];
	}
}
@end
