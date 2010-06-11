/**
 * <author name="David Chisnall"></author>
 */
#import <Foundation/Foundation.h>
#import <EtoileSerialize/ETSerializerBackend.h>

@protocol ETSerialObjectStore;
@class ETXMLWriter;

/**
 * Simple serializer which stores data in an XML format.
 */
@interface ETSerializerBackendXML : NSObject <ETSerializerBackend> {
	/** The store to which the xml data is written. */
	id<ETSerialObjectStore> store;
	/** A mapping from objects to their reference count. */
	NSMapTable * refCounts;
	/** The XML writer to use when generating XML. */
	ETXMLWriter *writer;
	/**
	 * Determines whether the store's -storeBytes:count: method is called or
	 * the XML writer will handle storing the data.
	 */
	BOOL xmlWriterWillStore;
}
- (void) setShouldIndent:(BOOL)aFlag;
@end
