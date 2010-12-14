//
//  GSDocBlock.h
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>

@class HtmlElement, DescriptionParser, DocIndex;

@interface DocElement : NSObject <NSCopying> 
{
	NSString *name;
	NSMutableString *rawDescription;
	NSString *filteredDescription;
	NSString *task;
	NSString *taskUnit;
}

@property (retain, nonatomic) NSString *task;
@property (retain, nonatomic) NSString *taskUnit;

- (NSString *) name;
- (void) setName: (NSString *)aName;

- (void) appendToRawDescription: (NSString *)aDescription;
- (NSString *) rawDescription;
- (void) setFilteredDescription: (NSString *)aDescription;
- (NSString *) filteredDescription;
- (void) addInformationFrom: (DescriptionParser *)aParser;

- (NSString *) insertLinksWithDocIndex: (DocIndex *)aDocIndex 
                             forString: (NSString *)aDescription;
- (NSString *) HTMLDescriptionWithDocIndex: (DocIndex *)aDocIndex;
- (HtmlElement *) HTMLRepresentation;

/** @taskunit GSDoc Parsing */

/** <override-dummy />
Returns the GSDoc element name to be parsed to initialize the instance.

Can be overriden to return an element name, and then called in the 
GSDocParserDelegate methods to reuse their implementation in a subclass 
hierarchy.<br />
For example, DocCDataType returns <em>type</em> and its subclass DocConstant 
returns <em>constant</em>, this way DocConstant doesn't override 
-parser:startElement:withAttributes: but inherits DocCDataType implementation:

<example>
	if ([elementName isEqualToString: [self GSDocElementName]])
	{
		[self setName: [attributeDict objectForKey: @"name"]];
		// more code
	}
</example>

By default, returns <em>type<em>. */
- (NSString *) GSDocElementName;
/** <override-dummy />
Returns the selector matching a CodeDocWeaving method, that should be used to 
weave the receiver into a page.

The returned selector must take a single argument.

e.g. -[(CodeDocWeaving) weaveOtherDataType:] or -[(CodeDocWeaving) weaveConstant:]. */
- (SEL) weaveSelector;

@end


@class Parameter;

@interface DocSubroutine : DocElement
{
	NSMutableArray *parameters;
	NSString *returnType;
}

- (void) setReturnType: (NSString *)aReturnType;
/** Returns the return type as an anonymous parameter object to which a HTML 
representation of the type can be asked. 

When generating the HTML representation for the return type, the parameter 
object will insert symbol links and apply standard formatting (e.g. class name 
+ space + star) as expected. */ 
- (Parameter *) returnParameter;
- (void) addParameter: (NSString *)aName ofType: (NSString *)aType;

@end

