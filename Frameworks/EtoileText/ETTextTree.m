#import <EtoileFoundation/EtoileFoundation.h>
#import "EtoileText.h"

/**
 * String object that represents all of the text contained in an ETText tree.
 */
@interface ETTextString : NSString
@property (nonatomic, retain) id<ETText> text;
@end
@implementation ETTextString
@synthesize text;
- (NSUInteger)length
{
	return [text length];
}
- (unichar)characterAtIndex: (NSUInteger)anIndex
{
	return [text characterAtIndex: anIndex];
}
- (void)dealloc
{
	[text release];
	[super dealloc];
}
@end

typedef struct 
{
	NSUInteger index;
	NSUInteger start;
} ETTextTreeChild;

@implementation ETTextTree
@synthesize length, parent, textType, customAttributes;
- (id)initWithChildren: (NSArray*)anArray
{
	SUPERINIT;
	children = [anArray mutableCopy];
	return self;
}
+ (ETTextTree*)textTreeWithChildren: (NSArray*)anArray
{
	return [[[self alloc] initWithChildren: anArray] autorelease];
}
- (id)init
{
	return [self initWithChildren: [NSArray array]];
}
- (void)dealloc
{
	[children release];
	[super dealloc];
}
- (NSString*)description
{
	NSString *typeName = [textType objectForKey: kETTextStyleName];
	NSMutableString *desc = [NSMutableString stringWithFormat: @"<%@>", typeName];
	for (id child in children)
	{
		[desc appendString: [child description]];
	}
	[desc appendFormat: @"</%@>", typeName];
	return desc;
}
- (ETTextTreeChild)childNodeForIndex: (NSUInteger)anIndex
{
	ETTextTreeChild childNode = { NSNotFound, 0};
	// FIXME: O(n)  No good!
	NSUInteger start = 0;
	NSUInteger childIndex = 0;
	for (id<ETText> child in children)
	{
		NSUInteger end = start + child.length;
		if (anIndex < end)
		{
			childNode.index = childIndex;
			childNode.start = start;
		}
		start = end;
		childIndex++;
	}
	return childNode;
}
- (void)appendTextFragment: (id<ETText>)aFragment
{
	length += [aFragment length];
	[children addObject: aFragment];
	aFragment.parent = self;
	[parent childDidChange: self];
}
- (unichar)characterAtIndex: (NSUInteger)anIndex
{
	ETTextTreeChild child = [self childNodeForIndex: anIndex];
	return [[children objectAtIndex: child.index] 
			characterAtIndex: (anIndex - child.start)];
}
- (void)recalculateLength
{
	// FIXME: O(n)  No good!
	NSUInteger newLength = 0;
	for (id<ETText> child in children)
	{
		newLength += child.length;
	}
	if (newLength != length)
	{
		length = newLength;
		[parent childDidChange: self];
	}
}
- (void)childDidChange: (id<ETText>)aChild
{
	[self recalculateLength];
}
- (void)replaceCharactersInRange: (NSRange)aRange
                      withString: (NSString*)aString
{
	// Special case for inserting into an empty tree
	if (0 == length && aRange.location == 0)
	{
		ETTextFragment *child = 
			[[ETTextFragment alloc] initWithString: aString];
		[children addObject: child];
		[child release];
		return;
	}
	ETTextTreeChild startChild = 
		[self childNodeForIndex: aRange.location];
	id<ETText> child = [children objectAtIndex: startChild.index];
	NSUInteger end = [child length];

	NSRange replaceRange = { aRange.location - startChild.start, aRange.length};

	// If this range is entirely inside this child
	if (end <= aRange.length)
	{
		[child replaceCharactersInRange: replaceRange 
		                     withString: aString];
		return;
	}

	replaceRange.length = end;
	// Get the end node index, before all of the index mappings change.
	ETTextTreeChild endChild = 
		[self childNodeForIndex: aRange.location + aRange.length];
	// Replace the range of text in the first child node with the replacement string
	[child replaceCharactersInRange: replaceRange 
	                     withString: aString];

	// Delete everything from the start child that's in the correct range.
	child = [children objectAtIndex: endChild.index];
	[child replaceCharactersInRange: replaceRange 
	                     withString: @""];

	if (endChild.index > startChild.index+1)
	{
		NSRange deleteRange = 
			{startChild.index+1, startChild.index+1 - endChild.index};
		[children removeObjectsInRange: deleteRange];
		[self recalculateLength];
	}
}
- (void)appendString: (NSString*)aString;
{
	// Special case for inserting into an empty tree
	if (0 == length)
	{
		ETTextFragment *child = 
			[[ETTextFragment alloc] initWithString: aString];
		[children addObject: child];
		[child release];
		return;
	}
	[[children lastObject] appendString: aString];
}
- (void)setCustomAttributes: (NSDictionary*)attributes 
                      range: (NSRange)aRange
{
	// We have several cases for setting custom attributes.  The range may
	// entirely cover one or more children.  Alternatively, it may partially
	// overlap some.

	// If the range is the entire node, set the attributes here.
	if (0 == aRange.location && aRange.length == length)
	{
		self.customAttributes = attributes;
		return;
	}
	ETTextTreeChild startChild = 
		[self childNodeForIndex: aRange.location];
	id<ETText> child = [children objectAtIndex: startChild.index];
	// If this range doesn't start on a child boundary, split the child
	if (startChild.start != aRange.location)
	{
		id prechild = [child splitAtIndex: aRange.location - startChild.start];
		[children insertObject: prechild
		               atIndex: startChild.index];
		startChild.start = aRange.location;
		startChild.index++;
	}
	do
	{
		NSUInteger childLength = [child length];
		// If the end is inside the child, we split the child once again, then
		// apply the attributes.
		if (childLength >= aRange.length)
		{
			id prechild = [child splitAtIndex: aRange.length];
			[children insertObject: prechild
			               atIndex: startChild.index];
			[prechild setCustomAttributes: attributes
			                        range: NSMakeRange(0, aRange.length)];
			return;
		}
		// Otherwise, set the attributes for the entire range.
		[child setCustomAttributes: attributes
		                     range: NSMakeRange(0, aRange.length)];
		// Process the next child
		startChild.index++;
		startChild.start += childLength;
		child = [children objectAtIndex: startChild.index];
	} while(nil != child);
}
- (NSUInteger)buildStyleFromIndex: (NSUInteger)anIndex
                 withStyleBuilder: (ETStyleBuilder*)aBuilder
{
	return -1;
}
- (id<ETText>)splitAtIndex: (NSUInteger)anIndex
{
	ETTextTreeChild splitChild = [self childNodeForIndex: anIndex];
	// If the split is not on a node boundary, split the child so that it is
	if (splitChild.start != anIndex)
	{
		id<ETText> child = [children objectAtIndex: splitChild.index];
		id prechild = [child splitAtIndex: anIndex - splitChild.start];
		[children insertObject: prechild
		               atIndex: splitChild.index];
		splitChild.index++;
	}
	NSRange firstRange = NSMakeRange(0, splitChild.index);
	// Construct the new node containing the first children
	NSArray *firstChildren = [children subarrayWithRange: firstRange];
	ETTextTree *firstPart = [ETTextTree textTreeWithChildren: firstChildren];
	firstPart.customAttributes = customAttributes;
	firstPart.textType = textType;
	// Remove the children that were added to the other node.
	[children removeObjectsInRange: firstRange];
	return firstPart;
}
- (void)visitWithVisitor: (id<ETTextVisitor>)aVisitor
{
	[aVisitor startTextNode: self];
	for (id<ETText> child in children)
	{
		[child visitWithVisitor: aVisitor];
	}
	[aVisitor endTextNode: self];
}
- (NSString*)stringValue
{
	ETTextString *str = [[ETTextString alloc] init];
	str.text = self;
	return [str autorelease];
}
- (void)replaceChild: oldChild withNode: aNode
{
	NSInteger idx = [children indexOfObjectIdenticalTo: oldChild];
	if (NSNotFound != idx)
	{
		if (nil == aNode)
		{
			[children removeObjectAtIndex: idx];
		}
		else
		{
			[children replaceObjectAtIndex: idx
			                    withObject: aNode];
		}
		[self recalculateLength];
	}
}
- (void)replaceInParentWithTextNode: (id<ETText>)aNode
{
	[(ETTextTree*)parent replaceChild: self withNode: aNode];
}
- (NSArray*)properties
{
	return A(@"textType", @"customAttributes");
}
- (BOOL)isOrdered
{
	return YES;
}
- (BOOL)isEmpty
{
	return [children count] == 0;
}
- (id)content
{
	return children;
}
- (NSArray*)contentArray
{
	return children;
}
@end

