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

+ (void)initialize
{
	if ([ETTextTree class] != self)
		return;

	[self applyTraitFromClass: [ETCollectionTrait class]];
	[self applyTraitFromClass: [ETMutableCollectionTrait class]];
}

+ (ETEntityDescription*)newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];
	
	// For subclasses that don't override -newEntityDescription, we must not add 
	// the property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [ETTextTree className]] == NO)
		return entity;

	// FIXME: Support protocol as type for ETText children
	ETPropertyDescription *children =
		[ETPropertyDescription descriptionWithName: @"children" type: (id)@"ETTextFragment"];
	[children setMultivalued: YES];
	[children setOrdered: YES];
	[children setOpposite: (id)@"ETTextFragment.parent"];
	// FIXME: Support protocol as type for ETTextGroup
	ETPropertyDescription *parent =
		[ETPropertyDescription descriptionWithName: @"parent" type: (id)@"ETTextTree"];
	[parent setIsContainer: YES];
	[parent setOpposite: (id)@"ETTextTree.children"];
	[parent setReadOnly: YES];
	// FIXME: Define accepted types for persisting textType
	ETPropertyDescription *textType =
		[ETPropertyDescription descriptionWithName: @"textType" type: (id)@"NSObject"];
	ETPropertyDescription *customAttributes =
		[ETPropertyDescription descriptionWithName: @"customAttributes" type: (id)@"NSDictionary"];
	ETPropertyDescription *stringValue =
		[ETPropertyDescription descriptionWithName: @"stringValue" type: (id)@"NSString"];
	[stringValue setDerived: YES];

	NSArray *transientProperties = A(stringValue);
	// FIXME: Include parent among the persistent properties once we support 
	// modeling relationships around EText/ETGroup protocols
	NSArray *persistentProperties = A(children, textType, customAttributes);
	
	[[persistentProperties mappedCollection] setPersistent: YES];
	[entity setPropertyDescriptions:
		[persistentProperties arrayByAddingObjectsFromArray: transientProperties]];
	
	return entity;
}

- (id)initWithChildren: (NSArray*)anArray
{
	SUPERINIT;
	children = [anArray mutableCopy];
	[(id <ETText>)[children mappedCollection] setParent: self];
	[self recalculateLength];
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
	[textType release];
	[customAttributes release];
	[super dealloc];
}

- (void) becomePersistentInContext: (COPersistentRoot*)aContext
{
	if ([self isPersistent])
		return;

	[super becomePersistentInContext: aContext];

	for (id <ETText> childNode in children)
	{
		ETAssert([childNode isKindOfClass: [COObject class]]);
		ETAssert([(COObject *)childNode isPersistent]);
		[(COObject *)childNode becomePersistentInContext: aContext];
	}
}

// FIXME: Disabled relationship consistency because
// -collectionForProperty:removalIndex: cannot access properties through ivar
// but only through KVC. In our case, -children returns a immutable array. So we
// need to implement ETInstanceVariableValueForKey(). Also in the long run, any
// text tree builder should disable relationship consistency temporarily for
// performance reasons (e.g. by setting -[COEditingContext checker] to nil).
- (void)updateRelationshipConsistencyForProperty: (NSString *)key oldValue: (id)oldValue
{
	
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
			break;
		}
		start = end;
		childIndex++;
	}
	return childNode;
}

- (void)insertTextFragment: (id<ETText>)aFragment atIndex: (NSUInteger)anIndex
{
	id oldCollection = [[children mutableCopy] autorelease];
	[self willChangeValueForProperty: @"children"];
	
	length += [aFragment length];
	if (ETUndeterminedIndex == anIndex)
	{
		[children addObject: aFragment];
	}
	else
	{
		[children insertObject: aFragment atIndex: anIndex];
	}
	aFragment.parent = self;
	[parent childDidChange: self];
	
	[self didChangeValueForProperty: @"children" oldValue: oldCollection];
}

- (void)appendTextFragment: (id<ETText>)aFragment
{
	[self insertTextFragment: aFragment atIndex: ETUndeterminedIndex];
}

- (void)removeTextFragment: (id<ETText>)aFragment
{
	id oldCollection = [[children mutableCopy] autorelease];
	[self willChangeValueForProperty: @"children"];
	
	length -= [aFragment length];
	[children removeObject: aFragment];
	aFragment.parent = nil;
	[parent childDidChange: self];
	
	[self didChangeValueForProperty: @"children" oldValue: oldCollection];
}

- (NSArray *)children
{
	return [NSArray arrayWithArray: children];
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

- (void)setStringValue: (NSString*)aString
{
	[children removeAllObjects];
	ETTextFragment *child = [[ETTextFragment alloc] initWithString: aString];
	[children addObject: child];
	[child release];
	[self recalculateLength];
	ETAssert([[self stringValue] isEqual: aString]);
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

- (BOOL)isOrdered
{
	return YES;
}

- (id) content
{
	return children;
}

- (NSArray *) contentArray
{
	return [NSArray arrayWithArray: children];
}

- (void) insertObject: (id)object atIndex: (NSUInteger)index hint: (id)hint
{
	[self insertTextFragment: object atIndex: index];
}

- (void) removeObject: (id)object atIndex: (NSUInteger)index hint: (id)hint
{
	[self removeTextFragment: object];
}

@end

