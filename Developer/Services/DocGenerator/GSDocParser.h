/**
	<abstract>GSDoc parser that can drive a DocPageWeaver through 
	DocWeaving protocol.</abstract>

	Copyright (C) 2008 Nicolas Roard

	Author:  Nicolas Roard
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2008
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import "DocPageWeaver.h"

@class DocHeader, DocMethod, DocFunction;
@class GSDocParser;

/** @group GSDoc Parsing

@abstract None

Parsing protocol usually implemented by DocElement subclass, so the parsing 
can be delegated per major XML elements (e.g. class, method etc.) to a newly 
instantied doc element and initialize it in this way.  */
@protocol GSDocParserDelegate
- (void) parser: (GSDocParser *)parser 
   startElement: (NSString *)anElement
  withAttributes: (NSDictionary *)theAttributes;
- (void) parser: (GSDocParser *)parser
     endElement: (NSString *)anElement
    withContent: (NSString *)aContent;
@end

/** @group GSDoc Parsing

Main GSDoc parser which wraps a NSXMLParser internally, handles the basic 
XML parsing and preprocessing, but delegates the rest to DocElement 
objects instantiated based on the class returned by -elementClassForName:.<br />
For example &lt;method&gt; is delegated to DocMethod through GSDocParserDelegate 
methods.

The parsing state is managed as a delegate parser stack that contains the 
receiver itself and zero or more DocElement objects pushed on top.

To parse a GDoc document, you have to initialize a new GSDocParser, use 
-setWeaver: to set the object which handles the parsing ouput such 
DocDeclarationReorderer or DocPageWeaver, and triggers the parsing with 
-parseAndWeave.

All XML parsing related methods are used internally, you can ignore them. */
@interface GSDocParser : NSObject <DocSourceParsing, GSDocParserDelegate, NSXMLParserDelegate>
{
	@private
	id <DocWeaving> weaver; /* Weak ref */
	NSXMLParser *xmlParser;
	NSMutableArray *parserDelegateStack;
	NSString *indentSpaces;
	NSString *indentSpaceUnit;
	NSMutableDictionary *elementClasses;
	NSSet *symbolElements;
	NSMutableDictionary *substitutionElements;
	NSSet *etdocElements;
	NSDictionary *escapedCharacters;
	NSMutableString *content;
	NSDictionary *currentAttributes;
	BOOL trimFoundCharacters;
}

/** @taskunit Initialization */

/** Returns a GSDoc parser initialized with the given GSDoc document.

Call -setWeaver: on the returned object to be ready to parse. */
- (id) initWithSourceFile: (NSString *)aSourceFile;
/** Sets the weaver on which the receiver should call back DocWeaving
methods while parsing the GSDoc XML provided at initialization time. */
- (void) setWeaver: (id <DocWeaving>)aDocWeaver;
/** Returns the weaver currently in use or nil. 

See also -setWeaver:. */
- (id <DocWeaving>) weaver;

/** Parses the GSDoc XML with which the receiver was initialized, and at the same 
time weaves the produced doc elements through DocWeaving methods.

DocElement subclass objects are created, when parsing an XML element to which 
a valid class is bound to with -elementClassForName:.

@task Parsing and Weaving */
- (void) parseAndWeave;

/**  @taskunit XML Parsing */

/** Reinitializes the current CDATA stored in the content variable. */
- (void) newContent;
/** Returns the class to be instantiated while parsing the given XML element.

When a valid class is returned, once instantiated, the parsing gets delegated 
to it through GSDocParserDelegate until the given XML element end is reached. */
- (Class) elementClassForName: (NSString *)anElementName;
/** Returns the current parser delegate.

The parser delegate is usually a DocElement object or the receiver iself.

Never returns nil. */
- (id <GSDocParserDelegate>) parserDelegate;
/** Pushes a new parser delegate to which the XML parsing should be delegated to.

Will be popped once we reach the end of the XML element that triggered the 
delegate creation.

You usually don't have to call this method, it is called each time 
-elementClassForName: returns a valid class.

The given delegate must not be nil.

See also -popParserDelegate and -parserDelegate. */
- (void) pushParserDelegate: (id <GSDocParserDelegate>)aDelegate;
/** Pops the last pushed parser delegate to which the XML parsing was delegated 
to until now.

You usually don't have to call this method, it is called each time we reach the 
end of an XML element bound to a valid class in -elementClassForName:.

See also -pushParserDelegate: and -parserDelegate. */
- (void) popParserDelegate;
/** Returns the current indenting in use.

The indentation varies each time a parser delegate is popped or pushed. */
- (NSString *) indentSpaces;

/** @taskunit XML Attribute Retrieval */

/** Returns the XML attributes in the last parsed element. */
- (NSDictionary *) currentAttributes;
/** Retrieves the value for the <em>type</em> key in the given XML attributes, 
usually retrieved with -currentAttributes when parsing the element <em>arg</em>, 
and returns the type or a blank string if no type is declared. */
- (NSString *) argTypeFromArgsAttributes: (NSDictionary *)attributeDict;

@end

#if DEBUG_PARSING
#define BEGINLOG() \
	NSLog(@"%@BEGIN <%@>", [parser indentSpaces], elementName);
#define CONTENTLOG() \
	NSLog(@"%@%@", [parser indentSpaces], trimmed);
#define ENDLOG() \
	NSLog(@"%@END   <%@> %@\n\n", [parser indentSpaces]);
#define ENDLOG2(a, b) \
	NSLog(@"%@END   <%@> %@\n\n", [parser indentSpaces], elementName, [NSString stringWithFormat: @"%@, %@", a, b]);
#define ENDLOG3(a, b, c) \
	NSLog(@"%@END   <%@> %@\n\n", [parser indentSpaces], elementName, [NSString stringWithFormat: @"%@, %@, %@", a, b, c]);
#else
#define BEGINLOG()
#define CONTENTLOG()
#define ENDLOG()
#define ENDLOG2(a, b)
#define ENDLOG3(a, b, c)
#endif
