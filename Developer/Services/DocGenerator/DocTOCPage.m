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

@interface DocPage (Private)
- (void) addElement: (DocElement *)anElement toDictionaryNamed: (NSString *)anIvarName forKey: (NSString *)aKey;
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
