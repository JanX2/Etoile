#import "ETSerialiser.h"

/**
 * A simple example back end which writes objects in a human-readable format
 * with C-like syntax.  This backend writes to the standard output if the URL
 * specified at creation is nil.  It is used for debugging the serialiser and
 * as an example for writing more complex backends.
 */
@interface ETSerialiserBackendExample : NSObject<ETSerialiserBackend> {
	/** File user for writing (defaults to stdout). */
	FILE * outFile;
	/** Current indent level. */
	unsigned int indent;
	/** Reference counts of written objects. */
	NSMutableDictionary * referenceCounts;
	/** Version of object graph. */
	int version;
}
@end
