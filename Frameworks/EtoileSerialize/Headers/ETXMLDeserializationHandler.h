/*
	Copyright (C) 2009 Niels Grewe

	Author:  Niels Grewe <niels.grewe@halbordnung.de>
	Date:  August 2009
	License: Modified BSD (see COPYING)
 */

#import <EtoileXML/ETXMLNullHandler.h>
#import <Foundation/Foundation.h>
@class ETDeserializer;
/**
 * ETXMLDeserializationHandler is a parser delegate that handles XML
 * nodes from a serialized object graph. It will create handlers of an
 * appropriate class for each child element in the graph, which will send
 * messages to the deserializer during parsing. The handler are transient and
 * will disappear sometime unless some child handler retains them.
 */
@interface ETXMLDeserializationHandler: ETXMLNullHandler
{
	/** The deserializer to use. */
	ETDeserializer *deserializer;

	/**
	 * Indicates whether the CORef of principal object (the first object under
	 * the current implementation) was already set in the backend.
	 */
	BOOL backendHasPrincipalRef;

	/**
	 *  Represents name attribute of the xml node. Not all elements in a
	 *  serialized object graph use a name attribute, but since it is fairly
	 *  common, it makes sense to place it here.
	 */
	NSString *name;
}
/**
 * Sets the name attribute to aName.
 */
- (void) setName: (NSString *)aName;

/**
 * Sets the deserializer to use.
 */
- (void) setDeserializer: (ETDeserializer *)aDeserializer;

/**
 * Recursively set the backendHasPrincipalRef flag for this handler and all its
 * ancestors.
 */
- (void) setBackendHasPrincipalRef: (BOOL)hasPrincipalRef;

 /**
  * Returns the backend from which the nodes stem.
  */
- (id) rootAncestor;

/**
 * Returns the name attribute of the xml node.
 */
- (char*) name;
@end

/**
 * This class handles the root &lt;objects&gt; node.
 */
@interface ETXMLobjectsDeserializationHandler: ETXMLDeserializationHandler
@end
