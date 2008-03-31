/**
 * <author name="David Chisnall"></author>
 */
#import <Foundation/Foundation.h>
#import <EtoileSerialize/ETSerializerBackend.h>

@protocol ETSerialObjectStore;

/**
 * Simple serializer which stores data in an XML format.
 */
@interface ETSerializerBackendXML : NSObject<ETSerializerBackend> {
	/** The store to which the binary data is written. */
	id<ETSerialObjectStore> store; 
	/** A mapping from objects to their reference count. */
	NSMapTable * refCounts;
	/** Flag indicating whether the XML should be indented */
	BOOL shouldIndent;
	/** The current indent level */
	unsigned indentLevel;
}
- (void) setShouldIndent:(BOOL)aFlag;
@end
