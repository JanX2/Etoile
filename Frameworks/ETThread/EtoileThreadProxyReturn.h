#import <Foundation/Foundation.h>
#include <pthread.h>

/**
 * The EtoileThreadProxyReturn class is used to implement futures.  It is returned
 * from a threaded object.
 */
@interface EtoileThreadProxyReturn : NSProxy {
	id object;
	pthread_cond_t conditionVariable;
	pthread_mutex_t mutex;
}
/**
 * Sets the object represented by the proxy.  Should only be called by EtoileThreadedObject.
 */
- (void) setProxyObject:(id)anObject;
/**
 * Returns the value represented by the object.
 */
- (id) value;
/**
 * Returns YES if the caller is a future, no otherwise.
 */
- (BOOL) isFuture;
@end
