#import <Foundation/Foundation.h>

/**
 * The Threaded category adds methods to NSObject
 * for creating object graphs in another thread.
 */
@interface NSObject (Threaded)
/**
 * Create an instance of the object in a new thread
 * with an associated run loop.
 */
+ (id) threadedNew;
/**
 * Executes the specified invocation in a new thread.
 * Returns a proxy object and completes asynchronously.
 */
- (id) invokeInNewThread:(NSInvocation*)anInvocation;
@end
