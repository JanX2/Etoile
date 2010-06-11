/**
 * <author name="David Chisnall"></author>
 */
#import <Foundation/Foundation.h>
#import <EtoileSerialize/ETSerializerBackend.h>

@protocol ETSeekableObjectStore;

/**
 * Simple serializer which stores data in a binary file using a type encoding
 * based on the GNU Objective-C runtime's format.  Note that this backend
 * currently only supports writing to file URLs.
 */
@interface ETSerializerBackendBinary : NSObject<ETSerializerBackend> {
	/** The store to which the binary data is written. */
	id<ETSeekableObjectStore> store; 
	/** A mapping from object references to offsets within the serialized file
	 */
	NSMapTable * offsets;
	/** A mapping from objects to their reference count. */
	NSMapTable * refCounts;
}
@end
