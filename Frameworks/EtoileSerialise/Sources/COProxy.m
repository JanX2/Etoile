#import "COProxy.h"
#import "ETSerialiser.h"
#import "ETSerialiserBackendBinaryFile.h"

static const int FULL_SAVE_INTERVAL = 100;

@implementation COProxy 
- (id) initWithObject:(id)anObject
           serialiser:(Class)aSerialiser
			forBundle:(NSURL*)anURL
{
	//Set a default URL for temporary objects
	if(anURL == nil)
	{
		anURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@ (%@).CoreObject",
			  NSTemporaryDirectory(),
			  [[NSProcessInfo processInfo] processName],
			  [[NSDate date] description]]];
	}
	//Only local file URLs are supported so far:
	if(![anURL isFileURL] || anObject == nil)
	{
		NSLog(@"Proxy creation failed.");
		[self release];
		return nil;
	}
	ASSIGN(object, anObject);
	//Find the correct proxy class:
	Class objectClass = [object class];
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
	ASSIGN(baseURL,anURL);
	if(aSerialiser == nil)
	{
		aSerialiser = [ETSerialiserBackendBinaryFile class];
	}
	backend = aSerialiser;
	serialiser = [[ETSerialiser serialiserWithBackend:aSerialiser 
								 			  forURL:baseURL] retain];
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
	[anInvocation setTarget:nil];
	[serialiser serialiseObject:anInvocation withName:"Delta"];
	[anInvocation setTarget:object];
	[anInvocation invoke];
	/* Periodically save a full copy */
	if(version % FULL_SAVE_INTERVAL == 0)
	{
		NSString * path = [NSString stringWithFormat:@"%@/FullSaves",
						 [baseURL path]];
		NSURL * fullsaveURL = [NSURL fileURLWithPath:path];
		ETSerialiser * s = [ETSerialiser serialiserWithBackend:backend
														forURL:fullsaveURL];
		[s serialiseObject:object withName:"FullSave"];
	}
}
@end
