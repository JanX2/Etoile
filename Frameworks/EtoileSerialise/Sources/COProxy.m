#import "COProxy.h"
#import "ETSerialiser.h"

static const int FULL_SAVE_INTERVAL = 100;
@implementation COProxy 
- (id) initWithObject:(id)anObject
           serialiser:(id)aSerialiser
{
	object = [anObject retain];
	//Find the correct proxy class:
	Class objectClass = [anObject class];
	Class proxyClass = Nil;
	while(objectClass != Nil)
	{
		if(Nil != (proxyClass = NSClassFromString([NSString stringWithFormat:@"COProxy_%s", objectClass->name])))
		{
			self->isa = proxyClass;
			break;
		}
		objectClass = objectClass->super_class;
	}
	serialiser = [aSerialiser retain];
	[serialiser serialiseObject:object withName:"BaseVersion"];
	return self;
}
- (int) version
{
	return version;
}
- (BOOL) setVersion:(int)aVersion
{
	return NO;
}
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	    return [object methodSignatureForSelector:aSelector];
}
/**
 * Forwards the invocation to the real object after serialising it.  Every few
 * invocations, it will also save a full copy of the object.
 */
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
