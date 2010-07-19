#import "ETTextProtocols.h"

@class ETXHTMLWriter;
/**
 * Protocol used for element handlers when writing XHTML.  This is similar to
 * the visitor protocol, but takes an ETXHTMLWriter as the first argument.
 */
@protocol ETXHTMLWriterDelegate
/**
 * Method called when entering a node for which this delegate is registered.
 */
- (void)writer: (ETXHTMLWriter*)aWriter startTextNode: (id<ETText>)aNode;
/**
 * Method called when traversing a leaf node for which this delegate is
 * registered.
 */
- (void)writer: (ETXHTMLWriter*)aWriter visitTextNode: (id<ETText>)aNode;
/**
 * Method called after visiting this node and all of its children.
 */
- (void)writer: (ETXHTMLWriter*)aWriter endTextNode: (id<ETText>)aNode;
@end

/**
 * ETXHTMLWriter is a visitor class that walks an EtoileText tree and generates
 * an XHTML document from it.  
 */
@interface ETXHTMLWriter : NSObject <ETTextVisitor>
{
	/** 
	 * Mapping from EtoileText types to XHTML tag names.  Used for one-to-one
	 * mappings.  More complex mappings require a delegate.
	 */
	NSMutableDictionary *types;
	/** Mapping from EtoileText type to tag attributes. */
	NSMutableDictionary *defaultAttributes;
	/** Mapping from EtoileText types to delegates for custom handling. */
	NSMutableDictionary *customHandlers;
	/** Flag indicating that the writer is current outputting footnotes. */
	BOOL isWritingFootnotes;
}
/** The XML writer object used for output. */
@property (nonatomic, retain) ETXMLWriter *writer;
/** 
 * Do not output anything until the specified node is ended.  Used, for
 * example, by footnotes to just output a number for the current footnote and
 * then emit a body of the footnote node later.
 */
@property (nonatomic, assign) id skipToEndOfNode;
/**
 * Sets the HTML tag name to use for a specified EtoileText type.  Ignored if a
 * delegate is set for this type.  If no tag name is specified for a type, span
 * is used.
 */
- (void)setTagName: (NSString*)aString forTextType: (NSString*)aType;
/**
 * Sets the default attributes to use for a specified EtoileText type.  If no
 * attributes are specified for a tag type, the class attribute is set to the
 * EtoileText type.
 */
- (void)setAttributes: (NSDictionary*)attributes forTextType: (NSString*)aType;
/**
 * Specifies a delegate to use for a specified EtoileText type.
 */
- (void)setDelegate: (id<ETXHTMLWriterDelegate>)aDelegate
        forTextType: (NSString*)aType;
/**
 * Ends the document and returns a string containing the XHTML rendition of it.
 */
- (NSString*)endDocument;
@end

/**
 * Class used for generating footnotes in XHTML output.
 */
@interface ETXHTMLFootnoteBuilder : NSObject <ETXHTMLWriterDelegate>
{
	/** Array of footnotes collected so far. */
	NSMutableArray *footnotes;
}
/**
 * Writes the collected footnote bodies to the provided writer.
 */
- (void)writeCollectedFootnotesForXHTMLWriter: (ETXHTMLWriter*)aWriter;
@end

/**
 * Class used for outputting headings as XHTML.  Maps EtoileText heading levels
 * to h1, h2, and so on.
 */
@interface ETXHTMLHeadingBuilder : NSObject <ETXHTMLWriterDelegate> @end

/**
 * Version of the heading builder that generates a link target for every
 * heading.  This is used when generating a table of contents.
 */
@interface ETXHTMLAutolinkingHeadingBuilder : ETXHTMLHeadingBuilder
{
	/** The number to use for the next heading. */
	int headingNumber;
}
@end

/**
 * Class that resolves references in an EtoileText tree. 
 */
@interface ETReferenceBuilder : NSObject <ETTextVisitor>
{
	/** Text nodes referring to other elements. */
	NSMutableArray *referenceNodes;
	/** Link targets. */
	NSMutableDictionary *linkTargets;
	NSMutableDictionary *linkNames;
	NSMutableDictionary *crossReferences;
	NSMutableArray *headings;
	/** Index entries. */
	NSMutableDictionary *indexEntries;
	int sectionCounter[10];
	int sectionCounterDepth;
}
- (void)finishVisiting;
@property (readonly) NSArray *referenceNodes;
@property (readonly) NSArray *headings;
@property (readonly) NSDictionary *linkTargets;
@property (readonly) NSDictionary *linkNames;
@property (readonly) NSDictionary *crossReferences;
- (void)writeTableOfContentsWithXMLWriter: (ETXMLWriter*)writer;
- (void)writeIndexWithXMLWriter: (ETXMLWriter*)writer;
@end

