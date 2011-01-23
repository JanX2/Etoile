/**
	<abstract>DocCategoryPage represents a page where all the categories on 
	the same class are regrouped.</abstract>

	Copyright (C) 2010 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  December 2010
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import "DocPage.h"

@class DocElementGroup;

/** @group Page Generation */
@interface DocCategoryPage : DocPage
{
	@private
	NSMutableArray *methodGroups;
}

/** Adds a method group representing a category documentation to the page. */
- (void) addMethodGroup: (DocElementGroup *)aMethodGroup;

@end
