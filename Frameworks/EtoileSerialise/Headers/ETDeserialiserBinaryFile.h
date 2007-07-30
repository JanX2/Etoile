/**
 * <author name="David Chisnall"></author>
 */
#import "ETDeserialiser.h"

/**
 * A simple deserialiser back end loading data from a binary file.  The
 * structure of this file is based loosely on the runtime type information
 * provided by the GNU Objective-C runtime.
 */
@interface ETDeserialiserBackendBinaryFile : NSObject <ETDeserialiserBackend>{
	/** The data from which to load the file. */
	NSData * data;
	/** A mapping from object references to offsets within the file. */
	NSMapTable * index;
	/** Reference counts for stored objects. */
	NSMapTable * refCounts;
	/** Deserialiser to use for reconstructing objects. */
	ETDeserialiser * deserialiser;
	/** Reference to the principle object in this graph. */
	CORef principalObjectRef;
}
@end
