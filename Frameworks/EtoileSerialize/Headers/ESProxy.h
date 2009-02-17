/**
 * <author name="David Chisnall"></author>
 */
#import <Foundation/Foundation.h>

@class ETSerializer;

/**
 * The ESProxy class is a simple proxy which is responsible for wrapping a
 * model object being managed by CoreObject.  The object will be serialized as
 * will every message sent to it, allowing deterministic replay of the object's
 * entire lifecycle.
 *
 * An object wrapped by this proxy should be the entry point into an object
 * graph representing a document, or a major component in a composite document
 * (e.g. an image in a larger work).  
 */
@interface ESProxy : NSProxy {
	/** The real object. */
	id object;
	/** The current version of the object. */
	int version;
	/** The location at which serialized copies of the object should be stored. */
	NSURL * baseURL;
	/** The serializer used to store deltas. */
	ETSerializer *serializer;
	/** Serializer used to store full saves */
	ETSerializer *fullSave;
	/** The class of the serializer's back end. */
	Class backend;
}
/**
 * Manage anObject, using aSerializer to for serialization
 */
- (id) initWithObject:(id)anObject
           serializer:(Class)aSerializer
			forBundle:(NSURL*)anURL;
/**
 * Restore to a previous version.
 */
- (int) setVersion:(int)aVersion;
@end
