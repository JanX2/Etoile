/*
 * Copyright (C) 2005  Stefan Kleine Stegemann
 *
 * The sources from MissigKit are not released under any particular
 * license. Do with them what ever you want to do. Include them in
 * your projects, use MissingKit standalone or simply ignore it.
 * Whatever you do, keep in mind the this piece of software may
 * have errors and that it is distributed WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.
 */

#ifndef _H_MKLRUCACHE
#define _H_MKLRUCACHE

#import "MKLinkedList.h"
#import <Foundation/Foundation.h>

/**
 * A cache with a restricted size. When the sum of the sizes of the
 * objects in the cache becomes bigger than the allowed size, objects
 * are removed from the cache until the sum of the size of the remaining
 * objects is smaller or equal than the allowed size. Objects are 
 * selected for removal from the cache using the least recently used
 * strategy.
 *
 * Objects that are stored in an MKLRUCache must implement the formal
 * protocol MKLRUCachable.
 *
 * Internally, the cache uses a linked list to keep track of the
 * object usages. Whenever an object is fetched from the cache, it is
 * put at the end of the list. When the cache needs to remove objects,
 * it selects objects from the beginning of the list. The time required
 * for the cache operations is the time for storing/retrieving objects
 * from an NSDictionary plus a constant amount of time for maitaining
 * the history list.
 */
@interface MKLRUCache : NSObject
{
   unsigned long         maxSize;
   unsigned long         size;
   NSMutableDictionary*  map;
   MKLinkedList*         history;
}

/** Intializes the receiver, a freshly allocated MKLRUCache with the
 *  specified maximum size.  */
- (id) initWithMaxSize: (unsigned long)aMaxSize;

/** Add an object to the cache using the specified key. Neither key nor
 *  object may be nil. Adding an object to the cache marks the object as
 *  recently used. If another object is currently associated with the
 *  specified key this object is replaced by anObject.  */
- (void) putObject: (id)anObject forKey: (id)aKey;

/** Fetch the object for the specified key from the cache. If the object
 *  was found, it is marked as recently used and returned. Returns nil
 *  if the cache doesn't have an object for the key.  */
- (id) objectForKey: (id)aKey;

/** Check if the receiver contains an object that is associated with the
 *  specified key.  */
- (BOOL) containsObjectForKey: (id)aKey;

/** Remove an object from the cache. Returns the object that has been removed
 *  or nil if no object is associated with the specified key.  */
- (id) removeObjectForKey: (id)aKey;

/** Remove all objects from the cache.  */
- (void) clear;

/** Set the maximum size for this cache. If necessary, objects are
 *  removed from the cache until the new maximum size is reached.  */
- (void) setMaximumSize: (long)aMaxSize;

/** Get the maximum size for this cache  */
- (unsigned long) maximumSize;

/** Get the number of objects in the cache.  */
- (unsigned) countObjects;

/** Get the current size of the cache. This is the sum of the
 *  sizes of the objects in the receiver.  */
- (unsigned long) size;

@end


/**
 * Informal Protocol for objects that are stored in a MKLRUCache.
 */
@interface NSObject (MKLRUCachable)

/** Get the size for the receiver in bytes . This is the size that is
 *  considered by MKLRUCaches.  */
- (unsigned long) sizeInLRUCache;

@end


/**
 * Some methods to verify the state of an MKLRUCache.
 */
@interface MKLRUCache (Testing)
@end

#endif
