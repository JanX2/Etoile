#import <EtoileFoundation/EtoileFoundation.h>
//#import <CoreObject/CoreObject.h>
#import "EtoileText.h"

@interface ETTextTree (Private)
- (void)replaceChild: oldChild withNode: aNode;
@end

@implementation ETTextFragment
@synthesize parent, textType, customAttributes;

+ (ETEntityDescription*)newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];
	
	// For subclasses that don't override -newEntityDescription, we must not add
	// the property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [ETTextFragment className]] == NO)
		return entity;
	
	// FIXME: Support protocol as type for ETTextGroup
	ETPropertyDescription *parent =
		[ETPropertyDescription descriptionWithName: @"parent" type: (id)@"ETTextTree"];
	[parent setIsContainer: YES];
	[parent setOpposite: (id)@"ETTextTree.children"];
	[parent setReadOnly: YES];
	ETPropertyDescription *stringValue =
		[ETPropertyDescription descriptionWithName: @"stringValue" type: (id)@"NSString"];
	// FIXME: Define accepted types for persisting textType
	ETPropertyDescription *textType =
		[ETPropertyDescription descriptionWithName: @"textType" type: (id)@"NSObject"];
	ETPropertyDescription *customAttributes =
		[ETPropertyDescription descriptionWithName: @"customAttributes" type: (id)@"NSDictionary"];

	NSArray *persistentProperties = A(stringValue, parent, textType, customAttributes);
	
	[[persistentProperties mappedCollection] setPersistent: YES];
	[entity setPropertyDescriptions: persistentProperties];
	
	return entity;
}

+ (id)fragmentWithString: (NSString*)aString
{
	return [[[self alloc] initWithString: aString] autorelease];
}

- (id)initWithString: (NSString*)string
{
	SUPERINIT;
	text = [string mutableCopy];
	return self;
}

- (id)init
{
	return [self initWithString: @""];
}
- (void) dealloc
{
	DESTROY(text);
	DESTROY(textType);
	DESTROY(customAttributes);
	[super dealloc];
}

- (NSString*)description
{
	NSString *typeName = [textType objectForKey: kETTextStyleName];
	if (nil == typeName)
	{
		return text;
	}
	return [NSString stringWithFormat: @"<%@>%@</%@>", typeName, text, typeName];
}

// FIXME: See same method comment in ETTextTree
- (void)updateRelationshipConsistencyForProperty: (NSString *)key oldValue: (id)oldValue
{
	
}

- (void)setCustomAttributes: (NSDictionary*)attributes 
                      range: (NSRange)aRange
{
	if (aRange.location != 0 || aRange.length != [text length])
	{
		[NSException raise: NSRangeException
		            format: @"Range for custom attributes must be entire leaf "
		                     "node.  You should split leaf nodes before modfying"
		                     "them if you need to modify a subrange"];
	}
	self.customAttributes = attributes;
}

- (void)replaceCharactersInRange: (NSRange)range
                      withString: (NSString*)aString
{
	[text replaceCharactersInRange: range
	                    withString: aString];
	[parent childDidChange: self];
}

- (void)appendString: (NSString*)aString
{
	[text appendString: aString];
	[parent childDidChange: self];
}

- (NSUInteger)buildStyleFromIndex: (NSUInteger)anIndex
                 withStyleBuilder: (ETStyleBuilder*)aBuilder
{
	[aBuilder addAttributesForStyle: textType];
	if (nil != customAttributes)
	{
		[aBuilder addCustomAttributes: customAttributes];
	}
	return [text length];
}

- (NSUInteger)length
{
	return [text length];
}

- (unichar)characterAtIndex: (NSUInteger)anIndex
{
	return [text characterAtIndex: anIndex];
}

- (id<ETText>)splitAtIndex: (NSUInteger)anIndex
{
	NSString *str = [text substringToIndex: anIndex];
	ETTextFragment *first = [[ETTextFragment alloc] initWithString: str];
	first.customAttributes = customAttributes;
	first.textType = textType;
	NSRange r = NSMakeRange(0, anIndex);
	[text deleteCharactersInRange: r];
	return [first autorelease];
}

- (void)visitWithVisitor: (id<ETTextVisitor>)aVisitor
{
	[aVisitor startTextNode: self];
	[aVisitor visitTextNode: self];
	[aVisitor endTextNode: self];
}

- (NSString*)stringValue
{
	return text;
}

- (void)setStringValue: (NSString*)aString
{
	[text setString: aString];
	[parent childDidChange: self];
}

- (void)replaceInParentWithTextNode: (id<ETText>)aNode
{
	[(ETTextTree*)parent replaceChild: self withNode: aNode];
}

@end
