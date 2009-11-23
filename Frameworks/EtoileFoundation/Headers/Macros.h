/*
 *  Macros.h
 *
 *  Created by David Chisnall on 02/08/2005.
 *
 */

/**
 * Simple macro for safely initialising the superclass.
 */
#define SUPERINIT if((self = [super init]) == nil) {return nil;}
/**
 * Deprecated. You should use the designated initializer rule.
 * 
 * Simple macro for safely initialising the current class.
 */
#define SELFINIT if((self = [self init]) == nil) {return nil;}
/**
 * Macro for creating dealloc methods.
 */
#define DEALLOC(x) - (void) dealloc { x ; [super dealloc]; }

@protocol MakeReleaseSelectorNotFoundErrorGoAway
- (void) release;
@end

/**
 * Cleanup function used for stack-scoped objects.
 */
__attribute__((unused)) static void ETStackAutoRelease(void* object)
{
	[*(id*)object release];
}
/**
 * Macro used to declare objects with lexical scoping.  The object will be sent
 * a release message when it goes out of scope.  
 *
 * Example:
 *
 * STACK_SCOPED Foo * foo = [[Foo alloc] init];
 */
#define STACK_SCOPED __attribute__((cleanup(ETStackAutoRelease))) 

/**
 * Set of macros providing a for each statement on collections, with IMP
 * caching.
 */
#define FOREACHI(collection,object) FOREACH(collection,object,id)

#define FOREACH(collection,object,type) FOREACH_WITH_ENUMERATOR_NAME(collection,object,type,object ## enumerator)

#define FOREACH_WITH_ENUMERATOR_NAME(collection,object,type,enumerator)\
NSEnumerator * enumerator = [collection objectEnumerator];\
FOREACHE(collection,object,type,enumerator)

#define FOREACHE(collection,object,type,enumerator)\
type object;\
IMP next ## object ## in ## enumerator = \
[enumerator methodForSelector:@selector(nextObject)];\
while(enumerator != nil && (object = next ## object ## in ## enumerator(\
												   enumerator,\
												   @selector(nextObject))))

#define D(...) [NSDictionary dictionaryWithObjectsAndKeys:__VA_ARGS__ , nil]
#define A(...) [NSArray arrayWithObjects:__VA_ARGS__ , nil]
#define S(...) [NSSet setWithObjects:__VA_ARGS__ , nil]

/**
 * Replacement for the GNUstep ASSIGN() macro providing a more efficient
 * version with fewer redundant tests and optimisations for infrequent cases.
 */
#ifdef ASSIGN
#undef ASSIGN
#define ASSIGN(var, obj) do {\
	id _tmp = [obj retain];\
	[var release];\
	var = _tmp;\
} while (0)
#endif

#ifdef DEFINE_STRINGS
#define EMIT_STRING(x) NSString *x = @"" # x;
#endif
#ifndef EMIT_STRING
#define EMIT_STRING(x) extern NSString *x;
#endif
