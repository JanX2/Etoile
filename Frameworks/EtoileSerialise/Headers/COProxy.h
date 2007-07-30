/**
 * <author name="David Chisnall"></author>
 */
#import <Foundation/Foundation.h>

/**
 * The COProxy class is a simple proxy which is responsible for wrapping a
 * model object being managed by CoreObject.  The object will be serialised as
 * will every message sent to it, allowing deterministic replay of the object's
 * entire lifecycle.
 *
 * An object wrapped by this proxy should be the entry point into an object
 * graph representing a document, or a major component in a composite document
 * (e.g. an image in a larger work).  
 */
@interface COProxy : NSProxy {
	/** The real object. */
	id object;
	/** The current version of the object. */
	int version;
	/** The location at which serialised copies of the object should be stored. */
	NSURL * baseURL;
	/** The serialiser used to store the document and any changes. */
	id serialiser;
	/** The serialiser's back end. */
	id backend;
}
/**
 * Manage anObject, using aSerialiser to for serialisation
 */
- (id) initWithObject:(id)anObject
           serialiser:(id)aSerialiser;
@end
