/**
 * <author name="David Chisnall"></author>
 */
#import "ETSerialiser.h"

/**
 * Simple serialiser which stores data in a binary file using a type encoding
 * based on the GNU Objective-C runtime's format.  Note that this backend
 * currently only supports writing to file URLs.
 */
@interface ETSerialiserBackendBinaryFile : NSObject<ETSerialiserBackend> {
	/** The file to which the binary data is written. */
	FILE * blobFile;
	/** The name of the file */
	NSString * fileName;
	/** A mapping from object references to offsets within the serialised file
	 */
	NSMapTable * offsets;
	/** A mapping from objects to their reference count. */
	NSMapTable * refCounts;
	/** Version of the object currently being written */
	int version;
}
@end
