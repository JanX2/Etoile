/*
	Copyright (C) 2010 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  December 2010
	License:  Modified BSD (see COPYING)
 */

#import "DocCategoryPage.h"
#import "DocHeader.h"
#import "DocCDataType.h"
#import "DocFunction.h"
#import "DocIndex.h"
#import "DocMethod.h"
#import "GSDocParser.h"
#import "DocHTMLElement.h"

@interface DocPage ()
- (DocHTMLElement *) HTMLRepresentationWithTitle: (NSString *)aTitle elements: (NSArray *)elements;
@end

@implementation DocCategoryPage

- (void) dealloc
{
	methodGroups = nil;
}

- (void) addMethodGroup: (DocElementGroup *)aMethodGroup
{
	if (methodGroups == nil)
	{
		methodGroups = [[NSMutableArray alloc] init];
	}
	[methodGroups addObject: aMethodGroup];
}

// TODO: This method shouldn't be invoked in DocPageWeaver and should be removed 
// in DocPage. The current method group can be memorized in DocPageWeaver.
- (void) addMethod: (DocMethod *)aMethod
{
	[[methodGroups lastObject] addElement: aMethod];
}

- (DocHTMLElement *) HTMLRepresentationForHeader: (DocHeader *)aHeader
{
	return [aHeader HTMLRepresentationWithTitleBlockElement: [H1 with: [aHeader title]]];
}

- (DocHTMLElement *) HTMLRepresentationForMethodGroupHeader: (DocHeader *)aHeader
{
	ETAssert([aHeader categoryName] != nil);

	return [aHeader HTMLRepresentationWithTitleBlockElement: [H2 with: [aHeader categoryName]]];
}

- (NSArray *) mainContentHTMLRepresentations
{
	NSMutableArray *reps = [NSMutableArray array];

	for (DocElementGroup *methodGroup in methodGroups)
	{
		H hHeader = [[methodGroup header] HTMLRepresentation];
		H hMethods = [self HTMLRepresentationWithTitle: nil elements: [methodGroup elementsBySubgroup]];

		[reps addObject: [DIV class: @"methodGroup" with: hHeader and: hMethods]];
	}

	return reps;
}

@end
