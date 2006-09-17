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

#import "MKLinkedList.h"

/**
 * Non-Public methods of MKLinkedList.
 */
@interface MKLinkedList (Private)
- (void) _setFirst: (MKLinkedListElement*)anElement;
- (void) _setLast: (MKLinkedListElement*)anElement;
@end

/**
 * Non-Public methods of MKLinkedListElement.
 */
@interface MKLinkedListElement (Private)
- (id) _initWithObject: (id)anObject list: (MKLinkedList*)aList;
- (void) _setList: (MKLinkedList*)aList;
- (void) _setNext: (MKLinkedListElement*)anElement;
- (void) _setPrevious: (MKLinkedListElement*)anElement;
@end


@implementation MKLinkedList

- (id) init
{
   self = [super init];
   if (self)
   {
      first = nil;
      last  = nil;
      size  = 0;
   }
   return self;
}

- (void) dealloc
{
   // remove remaining elements
   while ([self first])
   {
      [self remove: [self first]];
   }
   NSAssert(![self last], @"still elements in the list");
   [super dealloc];
}

- (MKLinkedListElement*) addObject: (id)anObject
{
   MKLinkedListElement* theElement;
   
   theElement = [[MKLinkedListElement alloc] _initWithObject: anObject list: self];
   [[self last] _setNext: theElement];
   [theElement _setPrevious: [self last]];
   [theElement _setNext: nil];
   [self _setLast: theElement];

   size++;
   
   // empty list?
   if (!first)
   {
      [self _setFirst: theElement];
   }

   return theElement;
}

- (MKLinkedListElement*) insertObject: (id)anObject
                               before: (MKLinkedListElement*)anElement
{
   MKLinkedListElement* theElement;
   
   if ([anElement list] != self)
   {
      [NSException raise: NSInvalidArgumentException
                  format: @"element does not belong to this list"];
   }
   
   theElement = [[MKLinkedListElement alloc] _initWithObject: anObject list: self];

   [theElement _setNext: anElement];
   [theElement _setPrevious: [anElement previous]];
   [[anElement previous] _setNext: theElement];
   [anElement _setPrevious: theElement];
   
   if (anElement == [self first])
   {
      [self _setFirst: theElement];
   }
   
   size++;

   return theElement;
}

- (MKLinkedListElement*) insertObject: (id)anObject
                 beforeElementAtIndex: (unsigned)anIndex
{
   return [self insertObject: anObject before: [self elementAtIndex: anIndex]];
}

- (void) remove: (MKLinkedListElement*)anElement
{
   if ([anElement list] != self)
   {
      [NSException raise: NSInvalidArgumentException
                  format: @"element does not belong to this list"];
   }

   size--;
   
   if (anElement == [self first])
   {
      [self _setFirst: [anElement next]];
   }
   
   if (anElement == [self last])
   {
      [self _setLast: [anElement previous]];
   }
   
   [[anElement previous] _setNext: [anElement next]];
   [[anElement next] _setPrevious: [anElement previous]];
   [anElement _setList: nil];
   [anElement release];
}

- (unsigned) count
{
   return size;
}

- (MKLinkedListElement*) first
{
   return first;
}

- (id) firstObject
{
   return [[self first] object];
}

- (MKLinkedListElement*) last
{
   return last;
}

- (id) lastObject
{
   return [[self last] object];
}

- (MKLinkedListElement*) elementAtIndex: (unsigned)anIndex
{
   unsigned middle;
   MKLinkedListElement* theElement = nil;
   
   if (anIndex >= [self count])
   {
      [NSException raise: NSRangeException
                  format: @"index %d is out of range", anIndex];
   }
   
   // start from end or from beginning?
   middle = (unsigned)([self count] / 2);
   if (anIndex < middle)
   {
      int i;
      theElement = [self first];
      for (i = 0; i < anIndex; i++)
      {
         theElement = [theElement next];
      }
   }
   else
   {
      int i;
      theElement = [self last];
      for (i = 0; i < ([self count] - (anIndex + 1)); i++)
      {
         theElement = [theElement previous];
      }
   }
   
   return theElement;
}

- (id) objectAtIndex: (int)anIndex
{
   return [[self elementAtIndex: anIndex] object];
}

- (void) makeLast: (MKLinkedListElement*) anElement
{
   if ([anElement list] != self)
   {
      [NSException raise: NSInvalidArgumentException
                  format: @"element does not belong to this list"];
   }

   if (anElement == [self last])
   {
      return;
   }
   
   if (anElement == [self first])
   {
      [self _setFirst: [anElement next]];
   }

   [[anElement previous] _setNext: [anElement next]];
   [[anElement next] _setPrevious: [anElement previous]];
   [[self last] _setNext: anElement];
   [anElement _setPrevious: [self last]];
   [anElement _setNext: nil];
   [self _setLast: anElement];
}

- (void) makeFirst: (MKLinkedListElement*) anElement
{
   if ([anElement list] != self)
   {
      [NSException raise: NSInvalidArgumentException
                  format: @"element does not belong to this list"];
   }

   if (anElement == [self first])
   {
      return;
   }
   
   if (anElement == [self last])
   {
      [self _setLast: [anElement previous]];
   }
   
   [[anElement previous] _setNext: [anElement next]];
   [[anElement next] _setPrevious: [anElement previous]];
   [[self first] _setPrevious: anElement];
   [anElement _setPrevious: nil];
   [anElement _setNext: [self first]];
   [self _setFirst: anElement];
}

@end


/* ----------------------------------------------------- */
/*  Category Private                                     */
/* ----------------------------------------------------- */

@implementation MKLinkedList (Private)

- (void) _setFirst: (MKLinkedListElement*)anElement
{
   first = anElement;
}

- (void) _setLast: (MKLinkedListElement*)anElement
{
   last = anElement;
}

@end


/* ----------------------------------------------------- */
/*  Class MKLinkedListElement                            */
/* ----------------------------------------------------- */

@implementation MKLinkedListElement

- (id) init
{
   self = [super init];
   if (self)
   {
      object   = nil;
      list     = nil;
      previous = nil;
      next     = nil;
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

- (MKLinkedListElement*) previous
{
   return previous;
}

- (MKLinkedListElement*) next
{
   return next;
}

- (MKLinkedList*) list
{
   return list;
}

@end


/* ----------------------------------------------------- */
/*  Category Private of MKLinkedListElement              */
/* ----------------------------------------------------- */

@implementation MKLinkedListElement (Private)

- (id) _initWithObject: (id)anObject list: (MKLinkedList*)aList
{
   self = [self init];
   if (self)
   {
      object = [anObject retain];
      [self _setList: aList];
   }
   return self;
}

- (void) _setList: (MKLinkedList*)aList
{
   list = aList;
}

- (void) _setNext: (MKLinkedListElement*)anElement
{
   next = anElement;
}

- (void) _setPrevious: (MKLinkedListElement*)anElement
{
   previous = anElement;
}

@end
