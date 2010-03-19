/*
	Copyright (C) 2009 Niels Grewe

	Author:  Niels Grewe <niels.grewe@halbordnung.de>
	Date:  July 2009
	License: Modified BSD (see COPYING)
 */

#import<Foundation/Foundation.h>
#import<EtoileFoundation/EtoileFoundation.h>
#import "ETUtility.h"
#import "ESCORefTable.h"
#include <limits.h>

/*
 * Imported from EtoileThread for the moment:
 * GCC 4.1 provides atomic operations which impose memory barriers.  These are
 * not needed on x86, but might be on other platforms (anything that does not
 * enforce strong ordering of memory operations, e.g. Itanium or Alpha).
 */
#if __GNUC__ < 4 || (__GNUC__ == 4 && __GNUC_MINOR__ < 1)
#warning Potentially unsafe memory operations being used
static inline void __sync_fetch_and_add(unsigned long *ptr, unsigned int value)
{
	*ptr += value;
}
#endif



static ESCORefTable *_sharedCORefTable;

@implementation ESCORefTable
+ (void) initialize
{
	if (self == [ESCORefTable class])
	{
		_sharedCORefTable = [[self alloc] init];
	}
}

+ (id) allocWithZone:( NSZone * )zone
{
	if (nil == _sharedCORefTable)
	{
		return [super allocWithZone: zone];
	}
	return nil;
}

+ (ESCORefTable*) sharedCORefTable
{
	return 	_sharedCORefTable;
}

- (id) init
{
	if (nil != _sharedCORefTable)
	{
		return _sharedCORefTable;
	}

	SUPERINIT
	const NSMapTableKeyCallBacks keycallbacks = {NULL, NULL, NULL, NULL, NULL, NSNotAnIntMapKey};
	const NSMapTableValueCallBacks valuecallbacks = {NULL, NULL, NULL};
	_pointerToCORefMap = NSCreateMapTable(keycallbacks, valuecallbacks, 100);

	// A CORef value of 0 would be indiscernible from the fact that a pointer is
	// not in the map table (NSMapGet would return NULL in this case as well).
	_nextCORef = 1;

	// _refCount maintains the number of serializers using the table.
	_refCount = 0;
	return self;
}

- (id) copyWithZone:(NSZone *)zone
{
	return self;
}

- (NSUInteger) retainCount
{
	return UINT_MAX;
}

- (void) release
{
	//Ignore, it's a singleton.
}

- (id) autorelease
{
	return self;
}
- (void) dealloc
{
	NSFreeMapTable(_pointerToCORefMap);
	[super dealloc];
}

- (void) use
{
	__sync_fetch_and_add(&_refCount,1);
}

- (void) done
{
	@synchronized(self)
	{
		if (0 == --_refCount)
		{
			NSResetMapTable(_pointerToCORefMap);
		}
	}
}

- (CORef) CORefFromPointer: (void*)aPointer
{
	uintptr_t theRef;
	@synchronized(self)
	{
		if (0 != (theRef = (uintptr_t)NSMapGet(_pointerToCORefMap, aPointer)))
		{
			return theRef;
		}
		theRef = _nextCORef++;
		NSMapInsert(_pointerToCORefMap, aPointer, (void *)(uintptr_t)theRef);
	}
	return theRef;
}
@end
