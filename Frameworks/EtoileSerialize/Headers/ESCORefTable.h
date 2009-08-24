/*
	Copyright (C) 2009 Niels Grewe

	Author:  Niels Grewe <niels.grewe@halbordnung.de>
	Date:  July 2009
	License: Modified BSD (see COPYING)
*/

#import <Foundation/Foundation.h>
#import "ETUtility.h"

/**
 * ESCORefTable maintains a global mapping of pointers and CORefs. It is
 * presently only used on 64bit architectures. A reference to the singleton
 * managing the  map table can be obtained with +sharedCORefMap.
 */
@interface ESCORefTable: NSObject
{
	NSMapTable *_pointerToCORefMap;
	CORef _nextCORef;
	NSUInteger _refCount;
}
/**
 * Returns the global pointer/CORef mapping object.
 */
+ (ESCORefTable*) sharedCORefTable;

/*
 * Any class that serializes a whole object graph should call -use on the
 * shared CORefMap prior to using it. This will prevent the internal map table
 * from being cleaned up during the operation.
 */
- (void) use;

/**
 * If a serializer does not want to use the shared CORefMap anymore, it can
 * waive its usage with -done. If no serializer is actively using it, the map
 * table will be cleaned up.
 */
- (void) done;

/**
 * Returns a CORef for aPointer, inserting the pair into the internal map table
 * if necessary.
 */
- (CORef) CORefFromPointer: (void *)aPointer;
@end
