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

#import "MKLRUCache.h"

/**
 * Holds a Cache entry.
 */
@interface LRUCacheEntry : NSObject
{
   id                   object;
   MKLinkedListElement* historyEntry;
}

- (id) initWithObject: (id)anObject historyEntry: (id)aHistoryEntry;
- (id) object;
- (void) setObject: (id)anObject;
- (MKLinkedListElement*) historyEntry;

@end


/**
 * Non-Public methods.
 */
@interface MKLRUCache (Private)
- (void) _shrinkToMaxSize;
@end


@implementation MKLRUCache

- (id) initWithMaxSize: (unsigned long)aMaxSize
{
   self = [super init];
   if (self)
   {
      maxSize = aMaxSize;
      size    = 0;
      map     = [[NSMutableDictionary alloc] init];
      history = [[MKLinkedList alloc] init];
   }
   return self;
}

- (void) dealloc
{
   [map release];
   [history release];
   [super dealloc];
}

- (void) putObject: (id)anObject forKey: (id)aKey
{
   LRUCacheEntry* newEntry;
   
   NSAssert(anObject, @"object must not be nil");
   NSAssert(aKey, @"key must not be nil");
   
   // check if the object fits into the cache theoretically
   if ([anObject sizeInLRUCache] > [self maximumSize])
   {
      [NSException raise: NSInvalidArgumentException
                  format: @"object does not fit into cache (%d > %d)",
                          [anObject sizeInLRUCache], [self maximumSize]];
   }

   // add to cache
   newEntry = [map objectForKey: aKey];
   if (newEntry)
   {
      size = size - [[newEntry object] sizeInLRUCache];
      [newEntry setObject: anObject];
   }
   else
   {
      MKLinkedListElement* historyEntry = [history addObject: aKey];
      
      newEntry = [[LRUCacheEntry alloc] initWithObject: anObject
                                          historyEntry: historyEntry];

      [map setObject: newEntry forKey: aKey];
      [newEntry release];
   }   

   size = size + [anObject sizeInLRUCache];
   [self _shrinkToMaxSize];
}

- (id) objectForKey: (id)aKey
{
   LRUCacheEntry* theEntry;
   
   NSAssert(aKey, @"key must not be nil");

   theEntry = [map objectForKey: aKey];
   if (theEntry)
   {
      [history makeLast: [theEntry historyEntry]];
   }
   return [theEntry object];
}

- (BOOL) containsObjectForKey: (id)aKey
{
   return ([map objectForKey: aKey] != nil);
}

- (id) removeObjectForKey: (id)aKey
{
   LRUCacheEntry*  theEntry;
   id              theObject;
   
   NSAssert(aKey, @"key must not be nil");
   
   theObject = nil;

   theEntry = [map objectForKey: aKey];
   if (theEntry)
   {
      [history remove: [theEntry historyEntry]];

      theObject = [[theEntry object] retain];
      size = size - [theObject sizeInLRUCache];
      [map removeObjectForKey: aKey];
      [theObject autorelease];
   }
   
   return theObject;
}

- (void) clear
{
   NSEnumerator* e = [[map allKeys] objectEnumerator];
   id aKey;
   while ((aKey = [e nextObject]))
   {
      [self removeObjectForKey: aKey];
   }
}
   
- (void) setMaximumSize: (long)aMaxSize
{
   if ([self maximumSize] != aMaxSize)
   {
      maxSize = aMaxSize;
      [self _shrinkToMaxSize];
   }
}

- (unsigned long) maximumSize
{
   return maxSize;
}

- (unsigned) countObjects
{
   return [map count];
}

- (unsigned long) size
{
   return size;
}

@end


/* ----------------------------------------------------- */
/*  Category Private                                     */
/* ----------------------------------------------------- */

@implementation MKLRUCache (Private)

/** Remove objects from the cache until the sum of the sizes of the
 *  objects in the cache is at most equal to the maximum size.  */
- (void) _shrinkToMaxSize
{
   while (([self size] > [self maximumSize]) && ([self countObjects] > 0))
   {
      MKLinkedListElement* aCandidate = [history first];
      NSAssert(aCandidate, @"no first element in history");
      [self removeObjectForKey: [aCandidate object]];
   }
}

@end

/* ----------------------------------------------------- */
/*  Category Testing                                     */
/* ----------------------------------------------------- */

@implementation MKLRUCache (Testing)
@end

/* ----------------------------------------------------- */
/*  Class LRUCacheEntry                                  */
/* ----------------------------------------------------- */

@implementation LRUCacheEntry

- (id) initWithObject: (id)anObject historyEntry: (id)aHistoryEntry
{
   self = [super init];
   if (self)
   {
      object       = [anObject retain];
      historyEntry = aHistoryEntry;
   }
   return self;
}

- (void) dealloc
{
   [self setObject: nil];
   [super dealloc];
}

- (id) object
{
   return object;
}

- (void) setObject: (id)anObject
{
   if (anObject == object)
      return;
   [object release];
   object = [anObject retain];
}

- (MKLinkedListElement*) historyEntry
{
   return historyEntry;
}

@end
