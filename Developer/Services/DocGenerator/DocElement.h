/**
	<abstract>Base class to represent element in a doc element tree.</abstract>

	Copyright (C) 2008 Nicolas Roard

	Author:  Nicolas Roard
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2008
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>

@class DocHTMLElement, DocDescriptionParser, DocIndex, DocHTMLIndex;

/** @group Doc Element Tree

DocElement is an abstract class, whose subclasses represents concrete 
nodes such as methods, constants, etc. in the documentation element tree.

Each DocElement subclass is expected to implement both the GSDoc parsing and 
HTML generation that pertains to the element type.

Any ETDoc markup parsing should be delegated to DocDescriptionParser, see 
-addInformationFrom:.

The doc element tree is rooted in a page. See DocPage. */
@interface DocElement : NSObject <NSCopying> 
{
	@private
	NSString *name;
	NSMutableString *rawDescription;
	NSString *filteredDescription;
	NSString *task;
	NSString *taskUnit;
	NSString *ownerSymbolName;
}

/** @taskunit Basic Documentation Properties */

/** Returns the task name returned by -task when no custom task was set.

The default task name is <em>Default</em>. */
+ (NSString *) defaultTask;
/** The element name. */
@property (retain, nonatomic) NSString *name;
/** The task to which the receiver belongs to. 

When a taskUnit is set on the receiver and the task is nil, the returned task 
is the taskUnit, otherwise +defaultTaskName is returned if both are nil.

See also +defaultTask. */
@property (retain, nonatomic) NSString *task;
/** The task to which the receiver, and the elements that follow it on the page, 
belongs to.

For example, every method whose task is nil and added to DocPage, will 
share the same task than the last previously added method whose task unit was 
not nil.

See also -task. */
@property (retain, nonatomic) NSString *taskUnit;

/** @taskunit Attached Description */

/** Returns the text to denote a empty description yet to be written.

For every missing or empty descriptions in a header or source file, autogsdoc 
inserts this text. */
+ (NSString *) forthcomingDescription;

/** Appends the given text to the raw description. 

For example, subclasses call this method in their GSDocParserDelegate method 
implementations.

See also -rawDescription. */
- (void) appendToRawDescription: (NSString *)aDescription;
/** Returns the raw description which still contains ETDoc markup. */
- (NSString *) rawDescription;
/** The final description with ETDoc markup such as <em>@task</em> filtered out.

DocDescriptionParser can be used to filter the raw description and 
-addInformationFrom: to retrieve it. */
@property (retain, nonatomic) NSString *filteredDescription;
/** Updates the receiver properties listed below based on the values parsed 
in the raw description by the given DocDescriptionParser object.

<list>
<item>task</item>
<item>task unit</item>
<item>filtered description</item>
</list>

You usually call this method to parse an element description and initialize the 
receiver. For example, when handling the closing tag in 
-[(GSDocParserDelegate) parser:endElement:withContent:] a subclass can do:

<example>
DocDescriptionParser *descParser = AUTORELEASE([[DocDescriptionParser alloc] init]);

[descParser parse: [self rawDescription]];
[self addInformationFrom: descParser];
</example>

Can be overriden in a subclass to update additional markup values. */
- (void) addInformationFrom: (DocDescriptionParser *)aParser;

/** @taskunit Link Insertion */

/** The class, category or protocol symbol that is valid to resolve local 
symbols in the element documentation.

As an example, -ownerSymbolName is a local symbol that is resolved and replaced 
by a link in -insertLinksWithDocIndex:forString:. */
@property (nonatomic, retain) NSString *ownerSymbolName;
/** Parses valid ETDoc symbol names in the given description and replaces them 
with links built by the given doc index.

Symbol names can be detected even when not surrounded by whitespaces, but 
enclosed by common punctuation patterns. */
- (NSString *) insertLinksWithDocIndex: (DocIndex *)aDocIndex 
                             forString: (NSString *)aDescription;

/** @taskunit HTML Generation */


/** Returns a HTML formatted description from the filtered description.

The returned description includes API symbol links.

See -filteredDescription. */
- (NSString *) HTMLDescriptionWithDocIndex: (DocHTMLIndex *)aDocIndex;
/** <override-dummy />
Returns the HTML element tree into which the receiver should be rendered.

By default, returns the +[DocHTMLElement blankElement].

Should be overriden to return a custom representation. */
- (DocHTMLElement *) HTMLRepresentation;


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

By default, returns <em>type</em>. */
- (NSString *) GSDocElementName;
/** <override-dummy />
Returns the selector matching a CodeDocWeaving method, that should be used to 
weave the receiver into a page.

The returned selector must take a single argument.

e.g. -[(CodeDocWeaving) weaveOtherDataType:] or -[(CodeDocWeaving) weaveConstant:]. */
- (SEL) weaveSelector;

@end


@class DocParameter;

/** @group Doc Element Tree
@abstract Base class to represent function-like constructs in a doc element tree.

DocSubroutine is an abstract class whose subclasses represent function-like 
constructs suchs methods, C functions or macros. */
@interface DocSubroutine : DocElement
{
	@private
	NSMutableArray *parameters;
	NSString *returnType;
}

/** @taskunit Returned Value */

/** Declares the return type. e.g. NSString * or void. */
- (void) setReturnType: (NSString *)aReturnType;
/** Returns the return type as an anonymous parameter object to which a HTML 
representation of the type can be asked. 

When generating the HTML representation for the return type, the parameter 
object will insert symbol links and apply standard formatting (e.g. class name 
+ space + star) as expected. */ 
- (DocParameter *) returnParameter;

/** @taskunit Parameters */

/** Declares a new parameter that follow any previously added parameters. */
- (void) addParameter: (DocParameter *)aParameter;
/** Returns the parameters. */
- (NSArray *) parameters;

@end

#define IS_NIL_OR_EMPTY_STR(x) (x == nil || [x isEqualToString: @""])
