/**
 * <author name="David Chisnall"></author>
 */
#import "ETSerializer.h"

/**
 * A simple example back end which writes objects in a human-readable format
 * with C-like syntax.  This backend writes to the standard output if the URL
 * specified at creation is nil.  It is used for debugging the serializer and
 * as an example for writing more complex backends.
 */
@interface ETSerializerBackendExample : NSObject<ETSerializerBackend> {
	id store;
	/** Current indent level. */
	unsigned int indent;
	/** Reference counts of written objects. */
	NSMutableDictionary * referenceCounts;
	/** Version of object graph. */
	int version;
}
@end
