#include <objc/objc.h>
#import <Foundation/Foundation.h>

/**
 * Structure storing information about object children.
 */
struct child_info
{
	/** Number of children of this class. */
	unsigned count;
	/** Offsets of children. */
	size_t *offsets;
	/** Method pointer for enumerating extra children. */
	IMP extra_children;
};

/**
 * Method for enumerating children of objects which respond to -objectEnumerator.
 */
void enumerateChildren(id self, SEL sel, IMP method, id object)
{
	NSEnumerator *e = [self objectEnumerator];
	IMP next = [e methodForSelector:@selector(nextObject)];
	id child;
   	while (nil !=( child = next(e, @selector(nextObject))))
	{
		method(child, sel, object);
	}
}

/**
 * Macro for adding an offset to the offset buffer and resizing it if required.
 */
#define ADD_OFFSET(offset) \
	do {\
	if (found == space)\
	{\
		space *= 2;\
		buffer = realloc(buffer, sizeof(size_t[space]));\
	}\
	buffer[found++] = offset;\
	} while(0)

// Note: If we want to save space we could use char*s and short*s for objects
// less than 2^8 and 2^16 big and add a header indicating this.
/**
 * Create an instance variable map for the specified class.  Inspects the ivars
 * metadata and creates a child_info structure for the class.  This is cached
 * in the gc_object_type field in the class structure.
 */
struct child_info *make_ivar_map(Class aClass)
{
	struct child_info *info = calloc(1, sizeof(struct child_info));
	//long end = aClass->instance_size;
	struct objc_ivar_list * ivar_list = aClass->ivars;
	if (NULL == ivar_list)
	{
		info->count = 0;
		info->offsets = NULL;
	}
	else
	{
		unsigned space = ivar_list->ivar_count;
		unsigned found = 0;
		// First guess - every instance variable is an object
		size_t * buffer = malloc(sizeof(size_t[space]));
		for (unsigned i=0 ; i<ivar_list->ivar_count ; ++i)
		{
			struct objc_ivar *ivar = &ivar_list->ivar_list[i];
			switch(ivar->ivar_type[0])
			{
				case _C_ID:
				{
					ADD_OFFSET(ivar->ivar_offset);
					break;
				}
				case _C_ARY_B:
				case _C_STRUCT_B:
				{
					if (strchr(ivar->ivar_type, '@'))
					{
						//FIXME: Parse structures and arrays correctly
						NSLog(@"Compound type found in class %@, type: %s is "
								"incorrectly handled", aClass, ivar->ivar_type);
					}
					break;
				}
			}
		}
		info->count = found;
		info->offsets = realloc(buffer, sizeof(size_t[found]));
	}
	if ([aClass instancesRespondToSelector:@selector(_forAllChildren:with:)])
	{
		info->extra_children = 
			[aClass instanceMethodForSelector:@selector(_forAllChildren:with:)];
	}
	else if ([aClass instancesRespondToSelector:@selector(objectEnumerator)])
	{
		info->extra_children = (IMP)enumerateChildren;
	}
	aClass->gc_object_type = info;
	return info;
}

/**
 * Category on NSDictionary allowing the child enumeration routines to work on
 * all keys as well as all values stored in the dictionary.
 */
@implementation NSDictionary (CycleDetection)
/**
 * Calls method with anObject as the argument on every key and every value
 * stored in the dictionary.
 */
- (void) _forAllChildren:(IMP)method with:(id)anObject
{
	NSEnumerator *e = [self keyEnumerator];
	IMP next = [e methodForSelector:@selector(nextObject)];
	id child;
   	while (nil !=( child = next(e, @selector(nextObject))))
	{
		method(child, _cmd, anObject);
	}
	e = [self objectEnumerator];
	next = [e methodForSelector:@selector(nextObject)];
   	while (nil !=( child = next(e, @selector(nextObject))))
	{
		method(child, _cmd, anObject);
	}
}
@end

/**
 * Calls method(child, sel, argument) on every child of object.  Uses the
 * instance variable map created by make_ivar_map() and calls the IMP field in
 * this structure for any instance variables that are automatically detectable.
 */
void for_all_children(id object, IMP method, SEL sel, id argument)
{
	Class cls = object->class_pointer;
	while (Nil != cls)
	{
		if (NULL == cls->gc_object_type)
		{
			make_ivar_map(cls);
		}
		struct child_info *info = cls->gc_object_type;
		for (unsigned i=0 ; i<info->count ; ++i)
		{
			id child = *(id*)(((char*)object) + info->offsets[i]);
			if (child != nil)
			{
				method(child, sel, argument);
				//for_all_children(child, method, sel, argument);
			}
		}
		if (NULL != info->extra_children)
		{
			info->extra_children(object, sel, method, argument);
		}
		cls = cls->super_class;
	}
}
/**
 * Modified version of the object header.  Stores a 16-bit reference count and
 * a 16-bit flags field.  Three bits of the flags are used for the object
 * colour and one to indicate if it is buffered.  
 */
struct obj_layout {
	unsigned short flags;
	unsigned short retained;
	NSZone	*zone;
};

/**
 * Version of NSIncrementExtraRefCount() which sets a 16-bit reference count.
 * Should eventually replace NSIncrementExtraRefCount().
 */
static inline unsigned int NSIncrementExtraRefCountS(id  anObject)
{
	volatile unsigned short * refcount = &((struct obj_layout*)anObject)[-1].retained;
	__asm__ __volatile__ ("lock addw $1, %0"
									  :"=m" (*refcount));
	return (unsigned int)refcount;
}
/**
 * Version of NSDecrementExtraRefCountWasZero() which sets a 16-bit reference
 * count.  Should eventually replace NSDecrementExtraRefCountWasZero().
 */
static inline unsigned int NSDecrementExtraRefCountWasZeroS(id  anObject)
{
	volatile unsigned short * refcount = &((struct obj_layout*)anObject)[-1].retained;
	__asm__ __volatile__ ("lock subw $1, %0"
									  :"=m" (*refcount));
	return *(short*)refcount < 0;
}
/**
 * Version of NSExtraRefCount() which gets a 16-bit reference count.  Should
 * eventually replace NSExtraRefCount().
 */
static inline unsigned int NSExtraRefCountS(id anObject)
{
	unsigned short refcount = ((struct obj_layout*)anObject)[-1].retained;
	return (unsigned int) refcount;
}

/**
 * Atomic compare and swap operation.  Currently x86 only.  Versions for other
 * architectures need adding.
 */
unsigned short GSCompareAndSwap(unsigned short *addr, unsigned short old, unsigned short new)
{
	 __asm__ __volatile__ ("cmpxchg %1,%2"
	                       : "=a"(old)
	                       : "r"(new), "m"(*addr), "0"(old)
	                       : "memory");
	  return old;
}
/**
 * Returns the flags a specified object.
 */
unsigned short GSObjectFlags(id anObject)
{
	return ((struct obj_layout*)anObject)[-1].flags;
}

/**
 * Tries to set the flags for a given object.  Returns the old value.
 */
unsigned short GSTrySetFlags(id anObject, unsigned short old, unsigned short value)
{
	return GSCompareAndSwap(&(((struct obj_layout*)anObject)[-1].flags), old, value);
}

/**
 * Cycle detection is a graph colouring algorithm.  This type specifies the
 * possible colours.
 */
typedef enum {
	green = 0,       // Acyclic
	black = 1,       // In use.
	grey = 2,        // Possible member of cycle
	white = 3,       // Member of garbage cycle
	purple = 4,      // Possible root of cycle
	orange = 6       // Currently being freed
}GCColor;

/**
 * The bit in the flags field used to indicate whether an object is buffered.
 */
const int buffered = 8;

/**
 * Debugging function used to return a colour as a human-readable string.
 */
__attribute__((unused))
static NSString *GCStringFromColour(GCColor aColour)
{
	switch(aColour)
	{
		case black: return @"black";
		case grey: return @"grey";
		case white: return @"white";
		case purple: return @"purple";
		case green: return @"green";
		case orange: return @"orange";
	}
	return @"Unknown";
}
/**
 * Returns the colour of the specified object.
 */
static GCColor colourOfObject(id anObject)
{
	return GSObjectFlags(anObject) & 0x7;
}
/**
 * Sets the colour of the specified object.
 */
static void setColourOfObject(id anObject, GCColor colour)
{
	unsigned oldFlags;
	unsigned newFlags;
	do
	{
		oldFlags = GSObjectFlags(anObject);
		newFlags = oldFlags;
		// Clear the old colour.
		newFlags &= 0xfff8;
		// Set the new colour
		newFlags |= colour;
	} while(GSTrySetFlags(anObject, oldFlags, newFlags) != oldFlags);
}

/**
 * Sets the buffered flag for a given object.
 */
static void setBuffered(id anObject, BOOL shouldBuffer)
{
	//fprintf(stderr, "Colouring object 0x%x %s\n", (unsigned) anObject, [GCStringFromColour(colour) UTF8String]);
	unsigned oldFlags;
	unsigned newFlags;
	do
	{
		oldFlags = GSObjectFlags(anObject);
		newFlags = oldFlags;
		// Clear the old colour.
		// Set the new colour
		if (shouldBuffer)
		{
			newFlags |= buffered;
		}
		else
		{
			newFlags &= ~buffered;
		}
	} while(GSTrySetFlags(anObject, oldFlags, newFlags) != oldFlags);
}

/**
 * Returns whether the specified object's buffered flag is set.
 */
static BOOL isObjectBuffered(id anObject)
{
	return GSObjectFlags(anObject) & buffered;
}

/**
 * Table of objects that have already been visualised.
 */
NSHashTable __thread drawnObjects;
/**
 * Recursively output connections from this object in GraphViz .dot format.
 */
void vizGraph(id self, SEL _cmd, NSString *parent)
{
	NSString *me = [NSString stringWithFormat:@"object%d", (unsigned)self];
	if (NULL != NSHashGet(drawnObjects, self))
	{
		if (nil != parent)
		{
			printf("\t%s -> %s\n", [parent UTF8String], [me UTF8String]);
		}
		return;
	}
	// Add the node:
	if (colourOfObject(self) == black)
	{
		printf("\t%s [style=filled, fillcolor=black, fontcolor=white, label=\"%s\"]\n", [me UTF8String], self->class_pointer->name);
	}
	else
	{
		printf("\t%s [style=filled, fillcolor=%s, label=\"%s\"]\n", [me UTF8String], [GCStringFromColour(colourOfObject(self)) UTF8String], self->class_pointer->name);
	}
	// Add the connection to the parent
	if (nil != parent)
	{
		printf("\t%s -> %s\n", [parent UTF8String], [me UTF8String]);
	}
	NSHashInsert(drawnObjects, self);
	for_all_children(self, (IMP)vizGraph, _cmd, me);
}
/**
 * Print a GraphViz-compatible graph of all objects reachable from this one and
 * their colours.
 */
void visObject(id object, NSString *graphName)
{
	drawnObjects = NSCreateHashTable(NSNonOwnedPointerHashCallBacks, 100);
	printf("digraph %s {\n", [graphName UTF8String]);
	vizGraph(object, @selector(vizGraph:), nil);
	printf("}\n");
	NSFreeHashTable(drawnObjects);
}


/**
 * Per-thread flag indicating that we are currently freeing cycles and so
 * should not actually free objects.
 */
static BOOL __thread freeingCycles = NO;
/**
 * Size of the static loop buffer.
 */
#define LOOP_BUFFER_SIZE 512
/**
 * Per-thread buffer into which objects that are potentially roots in garbage
 * cycles are stored.
 */
static id __thread loopBuffer[LOOP_BUFFER_SIZE];
/**
 * Insert point into per-thread loop buffer.
 */
static int __thread loopBufferInsert = 0;
/**
 * Per-thread buffer for objects which need freeing after collecting cycles.
 */
static id __thread freeBuffer[LOOP_BUFFER_SIZE];
/**
 * Insert point into the free buffer.
 */
static int __thread freeBufferInsert = 0;
/**
 * Overflow space when freeBuffer is full.
 */
static NSHashTable __thread * freeBufferOverflow = NULL;

/**
 * Scan children turning them black and incrementing the reference count.  Used
 * for objects which have been determined to be acyclic.
 */
void GCScanBlackChild(id self, SEL _cmd, ...)
{
	NSIncrementExtraRefCountS(self);
	if (colourOfObject(self) != black)
	{
		setColourOfObject(self, black);
		for_all_children(self, (IMP) GCScanBlackChild, _cmd, nil);
	}
}

/**
 * Scan objects turning them black if they are not part of a cycle and white if
 * they are.
 */
void GCScan(id self, SEL _cmd, ...)
{
	GCColor colour = colourOfObject(self);
	if (colour == grey)
	{
		if ((short)(NSExtraRefCountS(self)) > 0)
		{
			setColourOfObject(self, black);
			for_all_children(self, (IMP) GCScanBlackChild, _cmd, nil);
		}
		else
		{
			setColourOfObject(self, white);
			for_all_children(self, (IMP)GCScan, _cmd, nil);
		}
	}
}

/**
 * Collect objects which are coloured white.
 */
void GCCollectWhite(id self, SEL _cmd, ...)
{
	//fprintf(stderr, "Looking at object %x with colour %s\n", (unsigned) self, [GCStringFromColour(colourOfObject(self)) UTF8String]);
	if ((colourOfObject(self) == white)
	   &&
	   YES)
	   //!isObjectBuffered(self))
	{
		setColourOfObject(self, black);
		for_all_children(self, (IMP)GCCollectWhite, _cmd, nil);

		[self release];
	}
}

/**
 * Mark objects grey if are not already grey.
 */
void GCMarkGreyChildren(id self, SEL _cmd, ...)
{
	NSDecrementExtraRefCountWasZeroS(self);
	if (colourOfObject(self) != grey)
	{
		setColourOfObject(self, grey);
		for_all_children(self, (IMP)GCMarkGreyChildren, _cmd, nil);
	}
}
/**
 * Flag used to prevent recursive calls to GCCollectCycles.
 */
static BOOL __thread checking = NO;

/**
 * Collect garbage cycles.  Inspects every object in the loopBuffer and frees
 * any that are part of garbage cycles.  This is an implementation of the
 * algorithm described in:
 *
 * http://www.research.ibm.com/people/d/dfb/papers/Bacon01Concurrent.pdf
 *
 */
void GCCollectCycles(void)
{
	if(checking) return;
	checking = YES;
	//fprintf(stderr, "Starting to detect cycles...\n");
	// Mark Roots
	id next;
	for (unsigned i=0 ; i<LOOP_BUFFER_SIZE ; i++)
	{
		next = loopBuffer[i];
		if (nil == next) continue;
		if (!isObjectBuffered(next))
		{
			loopBuffer[i] = nil;
			continue;
		}
		GCColor colour = colourOfObject(next);
		if (colour == purple)
		{
			if (colourOfObject(next) != grey)
			{
				setColourOfObject(next, grey);
				for_all_children(next, (IMP)GCMarkGreyChildren,
						@selector(GCMarkGreyChildren), nil);
			}
		}
		else
		{
			setBuffered(next, NO);
			if ((colour == black) && (NSExtraRefCountS(next) < 0))
			{
				[next release];
			}
			loopBuffer[i] = nil;
		}
	}
	// Scan roots
	for (unsigned i=0 ; i<LOOP_BUFFER_SIZE ; i++)
	{
		next = loopBuffer[i];
		if (nil == next) continue;
		//fprintf(stderr, "scanning object...\n");
		GCScan(next, @selector(GCScan:));
	}
	freeingCycles = YES;
	for (unsigned i=0 ; i<LOOP_BUFFER_SIZE ; i++)
	{
		next = loopBuffer[i];
		if (nil == next) continue;
		GCCollectWhite(next, @selector(GCCollectWhite:));
	}
	freeingCycles = NO;
	for (unsigned i=0 ; i<freeBufferInsert ; i++)
	{
		next = freeBuffer[i];
		if (nil == next) continue;
		setBuffered(next, NO);
		[next release];
		freeBuffer[i] = nil;
	}
	loopBufferInsert = 0;
	if (NULL != freeBufferOverflow)
	{
		NSHashEnumerator e = NSEnumerateHashTable(freeBufferOverflow);
		while (nil != (next = NSNextHashEnumeratorItem(&e)))
		{
			setBuffered(next, NO);
			[next release];
		}
		NSEndHashTableEnumeration(&e);
		NSFreeHashTable(freeBufferOverflow);
		freeBufferOverflow = NULL;
	}
	checking = NO;
}

/**
 * Category on NSObject to support automatic cycle detection.
 */
@implementation NSObject (CycleDetection)
/**
 * Increments the 16-bit reference count.  Replaces version that sets a
 * one-word reference count.
 */
- (id) retain
{
	NSIncrementExtraRefCountS(self);
	return self;
}
/**
 * Decrements the reference count for an object.  If the reference count
 * reaches zero, calls -dealloc.  If the reference count is not zero then the
 * objectt may be part of a cycle.  In this case, it is addded to a buffer and
 * cycle detection is later invoked.
 */
- (void) release
{
	if (colourOfObject(self) == orange)
	{
		if (freeingCycles)
		{
			return;
		}
		NSDeallocateObject(self);
		return;
	}
	if (NSDecrementExtraRefCountWasZeroS(self))
	{
		setColourOfObject(self, orange);
		setBuffered(self, NO);
		// If we are freeing cycles, queue this to be really deallocated later
		if (freeingCycles)
		{
			if (freeBufferInsert >= LOOP_BUFFER_SIZE - 1)
			{
				if (NULL == freeBuffer)
				{
					freeBufferOverflow = NSCreateHashTable(NSNonRetainedObjectHashCallBacks, 100);
				}
				NSHashInsertIfAbsent(freeBufferOverflow, self);
			}
			else
			{
				freeBuffer[freeBufferInsert++] = self;
			}
		}
		[self dealloc];
	}
	else
	{
		if (colourOfObject(self) != green)
		{
			setColourOfObject(self, purple);
			setBuffered(self, YES);
			loopBuffer[loopBufferInsert++] = self;
			if (loopBufferInsert > LOOP_BUFFER_SIZE - 5)
			{
				GCCollectCycles();
			}
		}
	}
}
/**
 * Frees the object if we are not currently freeing cycles.  If we are, then
 * deallocation is deferred.
 */
- (void) dealloc
{
	if (freeingCycles)
	{
		return;
	}
	NSDeallocateObject(self);
}
@end

/**
 * Modified autorelease pool which performs automatic detection and collection
 * of garbage cycles.
 */
@interface LoopCheckingAutoreleasePool : NSAutoreleasePool {
}
@end
@implementation LoopCheckingAutoreleasePool
/**
 * Pose as NSAutoreleasePool.  
 */
+ (void) load
{
	[self poseAsClass:[NSAutoreleasePool class]];
}
/**
 * Collect autoreleased objects and then collect cycles from any objects still
 * live.
 */
- (void) dealloc
{
	[super dealloc];
	GCCollectCycles();
}
/**
 * Collect garbage cycles.
 */
- (void) drain
{
	GCCollectCycles();
}
@end

////////////////////////////////////////////////////////////////////////////////
// TESTING:
////////////////////////////////////////////////////////////////////////////////

/**
 * Simple object which stores pointers to two objects.  Used to test whether cycle detection is really working by creating garbage cycles and checking that they are free'd.
 */
@interface Pair : NSObject {
@public
	id a, b;
}
@end
@implementation Pair
/**
 * Create a new pair and enable cycle detection for it.
 */
+ (id) new
{
	id new = [super new];
	// Enable automatic cycle detection for this object.
	setColourOfObject(new, black);
	return new;
}
/**
 * Release both pointers and log that the object has been freed.
 */
- (void) dealloc
{
	fprintf(stderr, "Pair destroyed\n");
	[a release];
	[b release];
	[super dealloc];
}
@end

int main(int argc, char **argv, char **env)
{
	id pool = [NSAutoreleasePool new];
	pool = [NSAutoreleasePool new];
	Pair * a1 = [Pair new];
	Pair * a2 = [Pair new];
	Pair * a3 = [Pair new];
	Pair * a4 = [Pair new];
	Pair * a5 = [Pair new];
	a1->a = [a2 retain];
	a1->b = [a5 retain];
	a2->a = [a2 retain];
	a2->b = [a4 retain];
	a3->a = [a3 retain];
	a3->b = [a4 retain];
	a4->a = [a3 retain];
	a4->b = [a5 retain];
	a5->a = [a5 retain];
	a5->b = [a1 retain];
	a5->b = [NSObject new];
	visObject(a1, @"Test");
	// Check that we haven't broken anything yet...
	NSLog(@"Testing? %@", a1);
	[a1 release];
	[a2 release];
	[a3 release];
	[a4 release];
	[a5 release];
	//[pool drain];
	[pool release];
	fprintf(stderr, "Buffered Objects: %d\n", loopBufferInsert);
    return 0;
}
