/*
	Copyright (C) 2010 Quentin Mathe

	Authors:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  December 2010
	License:  Modified BSD (see COPYING)
 */

#import "DocMacro.h"

@implementation DocMacro

- (NSString *) GSDocElementName
{
	return @"macro";
}

- (SEL) weaveSelector
{
	return @selector(weaveMacro:);
}

@end
