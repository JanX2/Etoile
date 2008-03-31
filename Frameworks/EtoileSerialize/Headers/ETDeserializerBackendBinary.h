/**
 * <author name="David Chisnall"></author>
 */
#import <Foundation/Foundation.h>
#import <EtoileSerialize/ETDeserializerBackend.h>
#import <EtoileSerialize/ETUtility.h>

@class ETDeserializer;

/**
 * A simple deserializer back end loading data from a binary file.  The
 * structure of this file is based loosely on the runtime type information
 * provided by the GNU Objective-C runtime.
 */
@interface ETDeserializerBackendBinary : NSObject <ETDeserializerBackend>{
	/** The data store */
	id store;
	/** The name of hte current branch. */
	NSString * branch;
	/** The data from which to load the file. */
	NSData * data;
	/** A mapping from object references to offsets within the file. */
	NSMapTable * index;
	/** Reference counts for stored objects. */
	NSMapTable * refCounts;
	/** Deserializer to use for reconstructing objects. */
	ETDeserializer * deserializer;
	/** Reference to the principle object in this graph. */
	CORef principalObjectRef;
}
@end
