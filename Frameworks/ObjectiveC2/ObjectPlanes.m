#import <Foundation/Foundation.h>
#import "runtime.h"
#import "ObjectPlanes.h"

Class NSConstantStringClass;
Class GSCInlineStringClass;
@class NSConstantString;
@class GSCInlineString;

// Turns off all fprintf statements.  This is a quick hack while debugging.
// When I am convinced this code really works, I will remove the logging
// statements.
#define fprintf(...)

/** Static array for mapping object plane indexes to objects. */
static ETObjectPlane *ObjectPlanes[0xffff];
// Plane 0 is currently reserved
static int nextPlane = 1;

/** Set the plane ID for a new object. */
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
/**
 * Returns the ID of the plane for this object. 
 */
static short getPlaneID(id object)
{
	unsigned int planeID = *(unsigned int*)(((void**)object) - 2);
	planeID &= 0xffff0000;
	planeID >>= 16;
	return (unsigned short)planeID;
}
/**
 * Thread-local variable indicating the last message sender that was not self.
 * Note that this is not a stack.  If you need to track the sender then you
 * must store this yourself.  This is intended so that methods like
 * +objectWithSomeRequirements that call +alloc immediately can have the sender
 * of the first class message passed to +alloc trivially.
 *
 * Note that this is a horrible hack, and is only set for class messages.
 * Please don't use it if yo can possibly avoid it.
 */
__thread id objc_msg_sender;

@implementation ETObjectPlane
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
	zone = NSDefaultMallocZone();
	return self;
}
- (NSZone*)zoneForPlane
{
	return zone;
}
- (unsigned short)planeID
{
	return (unsigned short)index;
}
@end

@interface NSObject (NSCopyingHack)
- (id)copyWithZone: (NSZone*)aZone;
@end

@implementation NSObject (ObjectPlanes)
+ (id)allocInPlane: (ETObjectPlane*)aPlane;
{
	id object = [self allocWithZone: [aPlane zoneForPlane]];
	setPlaneID(object, [aPlane planeID]);
	return object;
}
- (ETObjectPlane*)objectPlane;
{
	return ObjectPlanes[getPlaneID(self)];
}
+ (id)alloc
{
	fprintf(stderr, "Sender in alloc is: %x\n", objc_msg_sender);
	return [self allocInPlane: [objc_msg_sender objectPlane]];
}
@end

/** Default method returned if the receiver is nil. */
id nil_method(id obj, SEL _cmd, ...) { return nil; }

/**
 * Message intercept function.  Looks up the method based on the sender and
 * receiver, delegating to the plane object if there is one.
 */
IMP objc_msg_lookup_sender(id receiver, SEL selector, id sender)
{
	fprintf(stderr, "Intercepting call from %x to %s\n", (int)(intptr_t)sender,
			sel_get_name(selector));
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
		if (sender != receiver)
		{
			fprintf(stderr, "Set sender to 0x%x\n", sender);
			objc_msg_sender = sender;
		}
		return objc_msg_lookup(receiver, selector);
	}
	else 
	{
		// If we are in plane-aware code
		unsigned short senderPlaneID = getPlaneID(sender);
		unsigned short receiverPlaneID = getPlaneID(receiver);
		if (senderPlaneID == receiverPlaneID)
		{
			fprintf(stderr, "Intraplane message\n");
			return objc_msg_lookup(receiver, selector);
		}
		fprintf(stderr, "Calling from plane %hd to plane %hd\n", senderPlaneID,
				receiverPlaneID);
		ETObjectPlane * sPlane = ObjectPlanes[senderPlaneID];
		ETObjectPlane * rPlane = ObjectPlanes[receiverPlaneID];
		if(rPlane != nil && rPlane->intercept != NULL)
		{
			return rPlane->intercept(sender, receiver, selector, sPlane, rPlane);
		}
		return objc_msg_lookup(receiver, selector);
	}
}
