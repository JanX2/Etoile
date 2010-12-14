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
#import "HtmlElement.h"


@implementation DocTOCPage

- (HtmlElement *) HTMLRepresentationForHeader: (DocHeader *)aHeader
{
	DocIndex *docIndex = [DocIndex currentIndex];
	H hOverview = [DIV id: @"overview" with: [H2 with: @"Overview"]];
	BOOL setOverview = NO;

	/* Insert Overview */
	// TODO: Delegate that to DocHeader

	/* Pack title and overview in a header html element */
	H hHeader = [DIV id: @"header" with: [H1 with: [aHeader title]]];

	if (setOverview) 
	{
		[hHeader with: hOverview];
	}

	return hHeader;
}

- (NSArray *) mainContentHTMLRepresentations
{
	NSMutableArray *reps = [NSMutableArray array];

	/*if ([[self header] title] != nil)
	{
		[reps addObject: [H1 with: [[self header] title]]];
	}*/
	
	for (NSString *group in [subheaders allKeys])
	{
		[reps addObject: [self HTMLRepresentationWithTitle: @"Classes, Protocols and Categories by Groups"
		                                       subroutines: subheaders
		                        HTMLRepresentationSelector: @selector(HTMLTOCRepresentation)]];
	}
	return reps;
}

@end
