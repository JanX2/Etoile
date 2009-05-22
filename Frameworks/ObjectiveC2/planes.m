// Don't bother compiling this file when we aren't building with support for
// sender-aware dispatch.
#ifdef __OBJC_SENDER_AWARE_DISPATCH__
#import <Foundation/Foundation.h>
#import "runtime.h"

Class NSConstantStringClass;
Class GSCInlineStringClass;
@interface ETConcreteObjectPlane : NSObject {
	@public 
	IMP (*intercept)(id, id, SEL, id, id);
	@protected
	unsigned int index;
}
@end
@class NSConstantString;
@class GSCInlineString;

static ETConcreteObjectPlane *ObjectPlanes[0xffff];
// Plane 0 is currently reserved
static int nextPlane = 1;

static short setPlaneID(id object, short spaceID)
{
	volatile unsigned int *idAddress = (unsigned int*)(((void**)object) - 2);
	unsigned int old, new;
	// The -retain and -release methods can be modifying this word at the same
	// time so we need to do an atomic test and set to ensure that the value we
	// have is the real value.
	do
	{
		old = *idAddress;
		new = spaceID << 16;
		new += old & 0xffff;
	} while(!__sync_bool_compare_and_swap(idAddress, old, new));
	return old;
}
static short getPlaneID(id object)
{
	unsigned int plainID = *(unsigned int*)(((void**)object) - 2);
	plainID &= 0xffff0000;
	plainID >>= 16;
	return (unsigned short)plainID;
}
@implementation ETConcreteObjectPlane
+ (void)load
{
	NSConstantStringClass = [NSConstantString class];
	GSCInlineStringClass = [GSCInlineString class];
}
- (id)init
{
	if (nil == (self = [super init])) { return nil; }
	index = __sync_fetch_and_add(&nextPlane, 1);
	NSCAssert(index < USHRT_MAX, @"Too many planes!");
	ObjectPlanes[index] = self;
	return self;
}
@end

__thread id objc_msg_sender;
id nil_method(id obj, SEL _cmd, ...) { return nil; }
IMP objc_msg_lookup_sender(id receiver, SEL selector, id sender)
{
	fprintf(stderr, "Intercepting call from %x to %s\n", sender, sel_get_name(selector));
	if(receiver == nil)
	{
		return (IMP)nil_method;
	}
	// Don't intercept messages to constant strings
	else if(sender == nil
		||
		receiver->class_pointer == NSConstantStringClass
		||
		receiver->class_pointer == GSCInlineStringClass
		||
		CLS_ISMETA(receiver->class_pointer))
	{
		return objc_msg_lookup(receiver, selector);
	}
	else 
	{
		// If we are in plane-aware code
		unsigned short senderPlaneID = getPlaneID(sender);
		unsigned short receiverPlaneID = getPlaneID(receiver);
		objc_msg_sender = sender;
		if (senderPlaneID == receiverPlaneID)
		{
			return objc_msg_lookup(receiver, selector);
		}
		printf("Calling from space %hd to space %hd\n", senderPlaneID,
				receiverPlaneID);
		ETConcreteObjectPlane * sPlane = ObjectPlanes[senderPlaneID];
		ETConcreteObjectPlane * rPlane = ObjectPlanes[receiverPlaneID];
		if(rPlane != nil && rPlane->intercept != NULL)
		{
			return rPlane->intercept(sender, receiver, selector, sPlane, rPlane);
		}
		return objc_msg_lookup(receiver, selector);
	}
}

#endif
