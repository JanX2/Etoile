#import <Foundation/Foundation.h>
#import "EtoileThread.h"
#include <pthread.h>

/**
 * The EtoileThreadedObject class represents an object which has its
 * own thread and run loop.  Messages that return either an object
 * or void will, when sent to this object, return asynchronously.
 *
 * For methods returning an object, an [EtoileThreadProxyReturn] will
 * be returned immediately.  Messages passed to this object will
 * block until the real return value is ready.
 *
 * In general, methods in this class should not be called directly.
 * Instead, the [NSObject(Threaded)+threadedNew] method should be 
 * used.
 */
@interface EtoileThreadedObject : NSProxy{
	id object;
	pthread_cond_t conditionVariable;
	pthread_mutex_t mutex;
	NSMutableArray * invocations;
	NSMutableArray * returns;
	id proxy;
	BOOL terminate;
	EtoileThread * thread;
}
/**
 * Create a threaded instance of aClass
 */
- (id) initWithClass:(Class) aClass;
/**
 * Create a thread and run loop for anObject
 */
- (id) initWithObject:(id) anObject;
/**
 * Method encapsulating the run loop.  Should not be called directly
 */
- (void) runloop:(id)sender;
@end
