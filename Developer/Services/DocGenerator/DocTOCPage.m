/*
	Copyright (C) 2010 Quentin Mathe

	Authors:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  December 2010
	License:  Modified BSD (see COPYING)
 */

#import "DocTOCPage.h"
#import "DocHeader.h"
#import "DocCDataType.h"
#import "DocFunction.h"
#import "DocIndex.h"
#import "DocMethod.h"
#import "GSDocParser.h"
#import "DocHTMLElement.h"
#import "DocGraphWriter.h"

@interface DocPage (Private)
- (void) addElement: (DocElement *)anElement toDictionaryNamed: (NSString *)anIvarName forKey: (NSString *)aKey;
- (ETKeyValuePair *) firstPairWithKey: (NSString *)aKey inArray: (NSArray *)anArray;
@end

@implementation DocTOCPage

- (DocHTMLElement *) HTMLRepresentationForHeader: (DocHeader *)aHeader
{
	/* Pack title and overview in a header html element */
	H hMeta = [DIV class: @"meta" with: [P class: @"metadesc" with: [EM with: [aHeader abstract]]]];

	return [DIV class: @"header" with: [H2 with: [aHeader title]]
	                              and: hMeta
	                              and: [aHeader HTMLOverviewRepresentation]];
}

/* DocPageWeaver inserts the subheaders out of order, and before also their group 
name is parsed and set. */
- (void) sortSubheaders
{
	NSArray *elementArrays = [subheaders valueForKey: @"value"];
	NSMutableArray *elements = [NSMutableArray array];

	// TODO: We should use a -flattenedCollection or similar
	for (NSArray *groupedElements in elementArrays)
	{
		[elements addObjectsFromArray: groupedElements];
	}

	NSSortDescriptor *groupSortDesc = AUTORELEASE([[NSSortDescriptor alloc] initWithKey: @"group" ascending: YES]);
	NSSortDescriptor *nameSortDesc = AUTORELEASE([[NSSortDescriptor alloc] initWithKey: @"name" ascending: YES]);

	[elements sortedArrayUsingDescriptors: [NSArray arrayWithObjects: groupSortDesc, nameSortDesc, nil]];

	RETAIN(elements);
	[subheaders removeAllObjects];

	for (DocHeader *element in elements)
	{
		[self addElement: element toDictionaryNamed: @"subheaders" forKey: [element group]];
	}
	RELEASE(elements);
}

/* I renamed GraphWriter class (.h & .m) to DocGraphWriter. */
- (void) addCategoryNodeNamed: (NSString *)categoryName 
                    className: (NSString *)className
                protocolNames: (NSArray *)adoptedProtocolNames
                toGraphWriter: (DocGraphWriter *)writer
{
	if (categoryName == nil)
		return;

	[writer addNode: categoryName];
	[writer setAttribute: @"URL" 
	                with: [[DocHTMLIndex currentIndex] linkForSymbolName: categoryName ofKind: @"categories"]
	                  on: categoryName];
	[writer setAttribute: @"shape" with: @"parallelogram" on: categoryName];
	[writer addEdge: categoryName to: className];
	for (NSString *adoptedProtocolName in adoptedProtocolNames)
	{
		[writer addEdge: categoryName to: adoptedProtocolName];
	}
}

/* I renamed GraphWriter class (.h & .m) to DocGraphWriter. */
- (void) addProtocolNodeNamed: (NSString *)protocolName 
                protocolNames: (NSArray *)adoptedProtocolNames
                toGraphWriter: (DocGraphWriter *)writer
{
	if (protocolName == nil)
		return;

	[writer addNode: protocolName];
	[writer setAttribute: @"URL" 
	                with: [[DocHTMLIndex currentIndex] linkForProtocolName: protocolName]
	                  on: protocolName];
	[writer setAttribute: @"shape" with: @"circle" on: protocolName];
	/* Cluster protocols together and prevent inheritance tree distortion */
	[writer setAttribute: @"group" with: @"protocols" on: protocolName];
	for (NSString *adoptedProtocolName in adoptedProtocolNames)
	{
		[writer addEdge: protocolName to: adoptedProtocolName];
	}
}

/* I renamed GraphWriter class (.h & .m) to DocGraphWriter. */
- (void) addClassNodeNamed: (NSString *)className 
           superclassNames: (NSString *)superclassName
             protocolNames: (NSArray *)protocolNames
             toGraphWriter: (DocGraphWriter *)writer
{
	if (className == nil)
		return;

	[writer addNode: className];
	[writer setAttribute: @"URL" 
	                with: [[DocHTMLIndex currentIndex] linkForClassName: className]
	                  on: className];
	[writer setAttribute: @"shape" with: @"box" on: className];
	/* Cluster classes together and prevent inheritance tree distortion due to adopted protocols */
	[writer setAttribute: @"group" with: @"classes" on: className];
	if (superclassName != nil)
	{
		[writer addEdge: className to: superclassName];
	}
	for (NSString *protocolName in protocolNames)
	{
		[writer addEdge: className to: protocolName];
	}
}

- (NSString *) graphImageLinkWithGroupName: (NSString *)aName elements: (NSArray *)elements
{
	DocGraphWriter *writer = AUTORELEASE([DocGraphWriter new]);
	NSArray *visibleSuperclassNames = (id)[[elements mappedCollection] className];
	/* Size to min width from Start Document global.css and some trial-and-error tests
	   TODO: Find out which is the precise width based on the css. */
	float inchWidth = 620 / 72;
	float inchHeight = 500 / 72;

	[writer setGraphAttribute: @"ratio" with: @"auto"];
	[writer setGraphAttribute: @"size" with: [NSString stringWithFormat: @"%0.2f, %0.2f", inchWidth, inchHeight]];

	for (DocHeader *methodGroupElement in elements)
	{
		NSString *superclassName = [methodGroupElement superclassName];
		BOOL isVisibleSuperclass = [visibleSuperclassNames containsObject: superclassName];

		/* The current element can be either a class, a protocol or a category.
                   Each node addition methods will insert a node or return immediately. */

		[self addClassNodeNamed: [methodGroupElement className] 
		        superclassNames: (isVisibleSuperclass ? superclassName : nil)
		          protocolNames: [methodGroupElement adoptedProtocolNames]
		          toGraphWriter: writer];

		[self addProtocolNodeNamed: [methodGroupElement protocolName] 
		             protocolNames: [methodGroupElement adoptedProtocolNames]
		             toGraphWriter: writer];

		[self addCategoryNodeNamed: [methodGroupElement categoryName] 
		                 className: [methodGroupElement className]
		             protocolNames: [methodGroupElement adoptedProtocolNames]
		             toGraphWriter: writer];
	}

	// FIXME: Ugly bug hacked around
	if ([aName rangeOfString: @"<p>"].location != NSNotFound)
		return @"";

	NSString *imgName = [NSString stringWithFormat: @"graph-%@.%@", aName, @"png"];
	imgName = [imgName stringByReplacingOccurrencesOfString: @" " withString: @"_"];
	NSString *imgPath = [[[DocIndex currentIndex] outputDirectory] stringByAppendingPathComponent: imgName];

	[writer layout];
	[writer generateFile: imgPath withFormat: @"png"];

	return [NSString stringWithFormat: @"<img src=\"%@\">%@</img>", imgName, [writer generateWithFormat: @"cmapx"]];
}

- (DocHTMLElement *) HTMLOverviewRepresentationForGroupNamed: (NSString *)aGroup
{
	return (DocHTMLElement *)[self graphImageLinkWithGroupName: aGroup
	                                elements: [[self firstPairWithKey: aGroup inArray: subheaders] value]];
}

- (NSArray *) mainContentHTMLRepresentations
{
	[self sortSubheaders];

	NSMutableArray *reps = [NSMutableArray array];

	[reps addObject: [self HTMLRepresentationWithTitle: nil
	                                          elements: subheaders
	                        HTMLRepresentationSelector: @selector(HTMLTOCRepresentation)
	                                    groupSeparator: HR]];

	return reps;
}

@end
