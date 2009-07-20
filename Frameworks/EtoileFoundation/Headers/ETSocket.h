#import <Foundation/NSObject.h>

/**
 * The ETSocket class provides a simple wrapper around a socket.  The socket is
 * opened when the object is created, and closed when it is destroyed.
 */
@interface ETSocket : NSObject
{
	/** Buffer used for receiving data. */
	unsigned char buffer[512];
	/** File handle encapsulating the socket.  Used for runloop integration. */
	NSFileHandle *handle;
	/** Reference to the delegate. */
	id delegate;
	/** OpenSSL context. */
	void *ssl;
	/** OpenSSL context. */
	void *sslContext;
	/** Array of filters used for filtering the output. */
	NSMutableArray *outFilters;
	/** Array of filters used for filtering the input. */
	NSMutableArray *inFilters;
}
/**
 * Returns a new socket connected to the specified host, with the specified
 * service name on the first protocol to respond.
 */
+ (id)socketConnectedToRemoteHost: (NSString*)aHost
                       forService: (NSString*)aService;
/**
 * Negotiates an SSL (client) connection.  Returns YES on success.
 */
- (BOOL)negotiateSSL;
/**
 * Sets the delegate.
 */
- (void)setDelegate: (id)aDelegate;
/**
 * Sends the specified data through the socket.  Throw ETSocketException if
 * sending failed.
 */
- (void)sendData: (NSData*)data;
@end

/**
 * Informal protocol for socket delegates.
 */
@interface NSObject (ETSocketDelegate)
/**
 * Handle data received over the specified socket.
 */
- (void)receivedData: (NSData*)aData fromSocket: (ETSocket*)aSocket;
@end
/**
 * Protocol for socket data filters.  Data sent or received by an ETSocket
 * instance will be pushed through a chain of filters conforming to this
 * protocol.
 */
@protocol ETSocketFilter
/**
 * Filter the data and return the result.  The caller must not retain a
 * reference to the argument; filters are permitted to modify the data in-place
 * and return the argument.
 */
- (NSMutableData*) filterData: (NSMutableData*)aData;
@end

/**
 * Exception thrown on abrupt termination.
 */
extern NSString *ETSocketException;
