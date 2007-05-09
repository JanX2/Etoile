/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import <Foundation/NSSet.h>
#import <Foundation/NSArray.h>

#import "DatabaseElement.h"

@protocol DatabaseElement;

@protocol Category <DatabaseElement>

/**
 * Returns the child elements in this category.
 */
-(NSArray*) elements;

/**
 * Inserts the given element in this category.
 * Returns YES if - and only if - the operation is a success.
 * Otherwise, NO is returned. The operation will fail when the
 * element is already contained in this category.
 *
 * The position argument is an integer between 0 and the number
 * of already existing database elements. A position of 0 inserts
 * the new element before the first and a position equaling the
 * number of elements inserts the new element after the last element.
 */
-(BOOL) insertElement: (id<DatabaseElement>)element
           atPosition: (int)index;

/**
 * This convenience method inserts a database element in a category
 * without caring about the position. See the documentation for
 * -insertElement:atPosition: for details.
 */
-(BOOL) insertElement: (id<DatabaseElement>)element;

/**
 * Removes the given database element from the category. On success,
 * YES is returned. This will only work if the element is a direct
 * child of the category.
 */
-(BOOL) removeElement: (id<DatabaseElement>)element;

/**
 * Recursively removes the given database element from the category.
 * On success, YES is returned. This also removes the element if it's
 * contained in a subcategory.
 */
-(BOOL) recursivelyRemoveElement: (id<DatabaseElement>)element;
@end


@interface GrrCategory : NSObject <Category>
{
    // the parent element of this component
    id<Category> parent;
    
    // the array which contains all subelements
    NSMutableArray* elements;
    
    // the category name
    NSString* name;
}


/**
 * Initialises a named category with an empty element list.
 */
-(id) initWithName: (NSString*) aName;

/**
 * Designated initialiser.
 */
-(id) initWithName: (NSString*) aName
          elements: (NSArray*) anElementsArray;

// see Component protocol
@end


