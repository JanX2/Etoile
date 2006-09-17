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

#ifndef _H_MKLINKEDLIST
#define _H_MKLINKEDLIST

#import <Foundation/Foundation.h>

@class MKLinkedListElement;

/**
 * A very simple but convenient implementation of a linked
 * list ADT. Elements of the List are decorated with an 
 * MKLinkedListElement that maintains the additional informations
 * for the list structure.
 */
@interface MKLinkedList : NSObject
{
   MKLinkedListElement*  first;
   MKLinkedListElement*  last;
   unsigned              size;
}

/** Create a new, empty list.  */
- (id) init;

/** Append the object at the end of the list. The object becomes the
 *  last element of the list. Returns the new MKLinkedListElement that
 *  is created for the object. The object is retained by the list.  */
- (MKLinkedListElement*) addObject: (id)anObject;

/** Insert an object before another object in the list. Returns the 
 *  MKLinkedListElement that is created for anObject. The object is
 *  retained by the list.  */
- (MKLinkedListElement*) insertObject: (id)anObject
                               before: (MKLinkedListElement*)anElement;

/** Shortcut for
 *  [list insertObject: anObject before: [list elementAtIndex: anIndex]] */
- (MKLinkedListElement*) insertObject: (id)anObject
                 beforeElementAtIndex: (unsigned)anIndex;

/** Remove an element from the list. The element and the element's object
 *  are released.  */
- (void) remove: (MKLinkedListElement*)anElement;

/** Get the number of elements in the receiver.  */
- (unsigned) count;

/** Get the first element in the list.  */
- (MKLinkedListElement*) first;

/** Shortcut for [[list first] object]. */
- (id) firstObject;

/** Get the last element in the list.  */
- (MKLinkedListElement*) last;

/** Shortcut for [[list last] object]. */
- (id) lastObject;

/** Get the a particular element from the list. Warning: this method
 *  method has a worse performance because the elements of the list
 *  are traversed in sequential order until the desired element has
 *  been found. The worst case performance for this method is O(n/2)
 *  where n is the size of the list.  */
- (MKLinkedListElement*) elementAtIndex: (unsigned)anIndex;

/** Shortcut for [[list elementAtIndex: anIndex] object]. See elementAtIndex
 *  for more informations.  */
- (id) objectAtIndex: (int)anIndex;

/** Make an element the last element of the list. The element that
 *  is currently at the last position will become the predecessor
 *  of the new last element.  */
- (void) makeLast: (MKLinkedListElement*) anElement;

/** Make an element the first element of the list. The element that
 *  is currently at the first position will become the successor of
 *  the new first element.  */
- (void) makeFirst: (MKLinkedListElement*) anElement;

@end


/**
 * When an object is inserted into an MKLinkedList, a corresponding
 * MKLinkedListElement is created that holds the element and some
 * more informations which allows the list to maintain it's structure.
 *
 * Note that it is not possible to create an MKLinkedListElement
 * explicitly. Creation (and also deletion) of MKLinkedListElements
 * is always done by an MKLinkedList.
 */
@interface MKLinkedListElement : NSObject
{
   id                    object;
   MKLinkedList*         list;
   MKLinkedListElement*  previous;
   MKLinkedListElement*  next;
}

/** Get the object that is decorated by the receiver. */
- (id) object;

/** Set the object that is decorated by the receiver. This will send
 *  a release message to the current object and a retain message to
 *  anObject.  */
- (void) setObject: (id)anObject;

/** Get the previous element in the list the receiver belongs to. Returns
 *  nil if this element is at the beginning of the list.  */
- (MKLinkedListElement*) previous;

/** Get the next element in the list the receiver belongs to. Returns nil
 *  if this element is at the end of the list.  */
- (MKLinkedListElement*) next;

/** Get the list the receiver belongs to.  */
- (MKLinkedList*) list;

@end

#endif
