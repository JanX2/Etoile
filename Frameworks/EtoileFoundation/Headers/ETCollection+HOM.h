/*
	ETCollection+HOM.h

	Higher-order messaging additions to ETCollection 

	Copyright (C) 2009 Niels Grewe

	Author:  Niels Grewe <niels.grewe@halbordnung.de>
	Date:  June 2009

	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice,
	  this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice,
	  this list of conditions and the following disclaimer in the documentation
	  and/or other materials provided with the distribution.
	* Neither the name of the Etoile project nor the names of its contributors
	  may be used to endorse or promote products derived from this software
	  without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
	THE POSSIBILITY OF SUCH DAMAGE.
 */

// Compatibility with non-clang compilers:
#ifndef __has_feature
#	define __has_feature(x) 0
#endif

#import <Foundation/Foundation.h>


@interface NSObject (ETEachHOM)
/**
 * If the receiver conforms to the ETCollection protocol, this method returns a
 * proxy that will let map and filter methods iterate over the contents of the
 * collection when it is used as an argument to a message. Note: If an each
 * proxy is passed to a message used as a filter predicate, "or"-semantics will
 * be applied.
 */
- (id) each;
@end

@protocol ETCollection, ETCollectionMutation;

@protocol ETCollectionHOM

/**
 * Returns a proxy object on which methods can be called. These methods will
 * cause a collection to be returned containing the elements of the original
 * collection mapped by the method call.
 */
- (id) mappedCollection;

/**
 * Returns a proxy object that can be used to perform a left fold on the
 * collection. The value of the first argument of any method used as a folding
 * method is taken to be the initial value of the accumulator. 
 */
- (id) leftFold;

/**
 * Returns a proxy object that can be used to perform a right fold on the
 * collection. The value of the first argument of any method used as a folding
 * method is taken to be the initial value of the accumulator.
 */
- (id) rightFold;

/**
 * Returns a proxy object the will use the next message received to coalesce the
 * receiver and aCollection into one collection by sending the message to every
 * element of the receiver with the corresponding element of the second
 * collection as an argument. The first argument (after the implicit receiver
 * and selector arguments) of the message is thus ignored.
 * The operation will stop at the end of the shorter collection.
 */
- (id) zippedCollectionWithCollection: (id<NSObject,ETCollection>)aCollection;

/**
 * Returns a collection with each element of the original collection mapped by
 * applying aBlock where aBlock takes one argument of type id and returns id.
 */
- (id) mappedCollectionWithBlock: (id)aBlock;

/**
 * Folds the collection by applying aBlock consecutively with the accumulator as
 * its first and each element as its second argument. If shallInvert is set to
 * YES, the folding takes place from right to left.
 */
- (id) injectObject: (id)initialValue intoBlock: (id)aBlock
          andInvert: (BOOL)shallInvert;

/**
 * Folds the collection by applying aBlock consecutively with the accumulator as
 * its first and each element as its second argument.
 */
- (id) injectObject: (id)initialValue intoBlock: (id)aBlock;

/**
 * Coalesces the receiver and the collection named by aCollection into one
 * collection by applying aBlock (where aBlock takes two arguments of type id)
 * to all element-pairs from the collection. The operation will stop at the end
 * of the shorter collection.
 */
- (id) zippedCollectionWithCollection: (id<NSObject,ETCollection>) aCollection
                             andBlock:(id)aBlock;

#if __has_feature(blocks)
/**
 * Returns a collection containing all elements of the original collection that
 * respond with YES to aBlock.
 */
- (id) filteredCollectionWithBlock: (BOOL(^)(id))aBlock;
#endif
@end

@protocol ETCollectionMutationHOM
/**
 * Returns a proxy object on which methods can be called. These methods will
 * cause each element in the collection to be replaced with the return value of
 * the method call.
 */
- (id) map;

/**
 * Returns a proxy object on which methods with return type BOOL can be called.
 * Only elements that respond with YES to the method call will remain in the
 * collection. If there are any object returning messages sent to the proxy
 * before the predicate, these messages will be applied to the elements in the
 * collection before the test is performed. It is thus possible to filter a
 * collection based on attributes of an object:
 * <code>[[[persons filter] firstName] isEqual: @"Alice"]</code>
 */
- (id) filter;

/**
 * Returns a proxy object which will coalesce the collection named by
 * aCollection into the first collection by sending all messages sent to the
 * proxy to the elements of the receiver with the corresponding element of
 * aCollection as an argument. The first argument of the message (after the
 * implicit receiver and selector arguments) is thus ignored. The operation will
 * stop at the end of the shorter collection.
 */
- (id) zipWithCollection: (id<NSObject,ETCollection>) aCollection;

/**
 * Replaces each element in the collection with the result of applying aBlock to
 * it. The blocks takes one argument of type id.
 */
- (void) mapWithBlock: (id)aBlock;

/**
 * Coalesces the second collection into the first by applying aBlock (where
 * aBlock takes two arguments of type id) to all element pairs. Processing will
 * stop at the end of the shorter collection.
 */
- (void) collectBlock: (id)aBlock
       withCollection: (id<NSObject,ETCollection>)aCollection;

#if __has_feature(blocks)
/**
 * Removes all elements from the collection for which the aBlock does not return
 * YES.
 */
- (void) filterWithBlock: (BOOL(^)(id))aBlock;
#endif
@end

/**
 * The ETCollectionHOMMapIntegration protocol defines a hook that collections can
 * use to tie into higher-order messaging if they need special treatment of
 * their elements.
 */
@protocol ETCollectionHOMMapIntegration

/**
 * This method will be called by the map- and zip-functions. If a class
 * implements a -mapInfo method the return value of that method will be passed
 * here. It can be used to pass information about the original state of the
 * collection.
 */
- (void) placeObject: (id)mappedObject
        inCollection: (id<ETCollectionMutation>*)aTarget
     insteadOfObject: (id)originalObject
             atIndex: (NSUInteger)index
 havingAlreadyMapped: (NSArray*)alreadyMapped
             mapInfo: (id)mapInfo;
@end

/**
 * The ETCollectionHOMMapIntegration protocol defines a hook that collections can
 * use to tie into higher-order messaging if they need special treatment of
 * their elements.
 */
@protocol ETCollectionHOMFilterIntegration
/**
 * This method will be called by the filter proxy.
 */
- (void) placeObject: (id)anObject
             atIndex: (NSUInteger)index
        inCollection: (id<ETCollectionMutation>*)aTarget
       basedOnFilter: (BOOL)shallInclude
        withSnapshot: (id)snapshot;
@end

@protocol ETCollectionHOMIntegration <ETCollectionHOMMapIntegration,ETCollectionHOMFilterIntegration>
@end


@interface NSArray (ETCollectionHOM) <ETCollectionHOM>
@end

@interface NSDictionary (ETCollectionHOM) <ETCollectionHOM,ETCollectionHOMIntegration>
- (NSArray*) mapInfo;
@end

@interface NSSet (ETCollectionHOM) <ETCollectionHOM>
@end

@interface NSIndexSet (ETCollectionHOM) <ETCollectionHOM> 
@end

@interface NSMutableArray (ETCollectionHOM) <ETCollectionMutationHOM,ETCollectionHOMMapIntegration>
@end

@interface NSMutableDictionary (ETCollectionHOM) <ETCollectionMutationHOM>
@end

@interface NSMutableSet (ETCollectionHOM) <ETCollectionMutationHOM, ETCollectionHOMMapIntegration>
@end

@interface NSMutableIndexSet (ETCollectionHOM) <ETCollectionMutationHOM, ETCollectionHOMMapIntegration>
@end
