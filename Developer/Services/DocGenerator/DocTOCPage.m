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
#import "GraphWriter.h"

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

- (NSString *) graphImageLinkWithGroupName: (NSString *)aName elements: (NSArray *)elements
{
	GraphWriter *writer = AUTORELEASE([GraphWriter new]);

	for (DocHeader *methodGroupElement in elements)
	{
		if ([methodGroupElement className] == nil)
			continue;

		[writer addNode: [methodGroupElement className]];
			[writer setAttribute: @"URL" 
			                with: [[DocHTMLIndex currentIndex] linkForClassName: [methodGroupElement className]]
			                  on: [methodGroupElement className]];
		if ([methodGroupElement superclassName] != nil)
		{
			[writer addEdge: [methodGroupElement className] to: [methodGroupElement superclassName]];
		}
	}

	if ([aName rangeOfString: @"<p>"].location != NSNotFound)
		return @"";

	NSString *imgPath = [NSString stringWithFormat: @"graph-%@.%@", aName, @"png"];
	imgPath = [imgPath stringByReplacingOccurrencesOfString: @" " withString: @"_"];
	imgPath = [[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent: imgPath];

	[writer layout];
	[writer generateFile: imgPath withFormat: @"png"];

	return [NSString stringWithFormat: @"<img src=\"%@\">%@</img>", imgPath, [writer generateWithFormat: @"cmapx"]];
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
