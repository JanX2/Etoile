/*
	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2009
	License: Modified BSD (see COPYING)
 */
 
#import "ETXHTMLRenderContext.h"
#import "ETXHTMLWriter.h"


@implementation ETXHTMLRendering

+ (id) render: (id)anObject
{
	ETXHTMLWriter *writer = AUTORELEASE([[ETXHTMLWriter alloc] init]);
	ETXHTMLRendering *renderer = AUTORELEASE([[self alloc] initWithWriter: writer]);
	[renderer render: anObject];
	return [writer stringValue];
}

- (id) initWithWriter: (ETXHTMLWriter *)aWriter // could ETYUIWriter
{
	SUPERINIT
	ASSIGN(writer, aWriter);
	return self;
}

DEALLOC(DESTROY(writer));

@end


@implementation ETXHTMLRenderContext

+ (id) contextWithWriter: (ETXHTMLWriter *)aWriter
{
	return AUTORELEASE([[self alloc] initWithWriter: aWriter]);
}

/** Renders the given object by invoking the -renderXXX method matching its type 
name. 

Returns nil. */
- (id) render: (id)anObject
{
	if ([anObject isGroup])
	{
		[self renderItemGroup: anObject];
	}
	else
	{
		[self renderItem: anObject];
	}
	return nil;
}

- (void) renderItem: (ETLayoutItem *)anItem
{
	[self renderDecoratorItem: [anItem decoratorItem]];
}

- (void) renderItemGroup: (ETLayoutItemGroup *)anItem
{

}

- (void) renderDecoratorItem: (ETDecoratorItem *)aDecorator
{
	/* First render outermost decorator */
	if (aDecorator != nil)
	{
		[self renderDecoratorItem: aDecorator];
	}

	[self render: aDecorator];
}

- (void) renderWindowItem: (ETWindowItem *)anItem
{
	return nil;
}

- (void) renderScrollableAreaItem: (ETScrollableAreaItem *)anItem
{
	return nil;
}

@end
