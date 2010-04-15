#import "EtoileText.h"

@interface ETTextTree ()
- (void)recalculateLength;
@end
@interface ETTextTree (Builder)
- (void)replaceLastChildWithText: (id<ETText>)anObject;
@end

@implementation ETTextTree (Builder)
- (void)replaceLastChildWithText: (id<ETText>)anObject
{
	if ([children count] > 0)
	[children removeLastObject];
	[children addObject: anObject];
	anObject.parent = self;
	[self recalculateLength];
}
@end

@implementation ETTextTreeBuilder
@synthesize textTree;
- (id)init
{
	SUPERINIT;
	textTypeStack = [NSMutableArray new];
	textTree = [ETTextTree new];
	insertNode = textTree;
	return self;
}
- (void)dealloc
{
	[textTypeStack release];
	[textTree release];
	[super dealloc];
}
- (void)startNodeWithStyle: (id)aStyle
{
	[textTypeStack addObject: aStyle];
	ETTextFragment *fragment = [ETTextFragment new];
	fragment.textType = aStyle;
	if ([insertNode isKindOfClass: [ETTextTree class]])
	{
		[(ETTextTree*)insertNode appendTextFragment: fragment];
	}
	else
	{
		ETTextTree *newParent = [ETTextTree new];
		ETTextTree *parent = insertNode.parent;
		newParent.textType = insertNode.textType;
		insertNode.textType = nil;
		[newParent appendTextFragment: insertNode];
		[newParent appendTextFragment: fragment];
		[parent replaceLastChildWithText: newParent];
	}
	insertNode = fragment;
	[fragment release];
}
- (void)endNode
{
	if ([textTypeStack count] == 0) { return; }

	[textTypeStack removeLastObject];
	id textType = [textTypeStack lastObject];
	do
	{
		insertNode = insertNode.parent;
	}
	while (!((textType == insertNode.textType) ||
			[textType isEqual: insertNode.textType]));
}
- (void)appendString: (NSString*)aString
{
	if ([insertNode isKindOfClass: [ETTextTree class]])
	{
		ETTextFragment *fragment = 
			[[ETTextFragment alloc] initWithString: aString];
		[(ETTextTree*)insertNode appendTextFragment: fragment];
		[fragment release];
	}
	else
	{
		[insertNode appendString: aString];
	}
}
@end
