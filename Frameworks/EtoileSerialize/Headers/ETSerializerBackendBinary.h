/**
 * <author name="David Chisnall"></author>
 */
#import "ETSerializer.h"

/**
 * Simple serializer which stores data in a binary file using a type encoding
 * based on the GNU Objective-C runtime's format.  Note that this backend
 * currently only supports writing to file URLs.
 */
@interface ETSerializerBackendBinary : NSObject<ETSerializerBackend> {
	/** The URL to which the binary data is written */
	NSURL * url;
	/** The store to which the binary data is written. */
	id<ETSerialObjectStore> store; 
	/** A mapping from object references to offsets within the serialized file
	 */
	NSMapTable * offsets;
	/** A mapping from objects to their reference count. */
	NSMapTable * refCounts;
}
@end
