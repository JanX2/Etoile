/*
   Copyright (C) 2009 Nicolas Roard <nicolas@roard.com>

   This application is free software; you can redistribute it and/or
   modify it under the terms of the MIT license. See COPYING.
*/

#import "ModelClass.h"
#import "ModelMethod.h"

static NSString* ALL = @"-- All --";
static NSString* AYU = @"<< As yet Undefined >>";

@implementation ModelClass

- (id) init
{
	self = [super init];
	methods = [NSMutableArray new];
  	categories = [NSMutableDictionary new]; 
	properties = [NSMutableArray new];
	parent = [[NSString alloc] initWithString: @"NSObject"];
	[self setupDocumentation];
  	return self;
}

- (void) dealloc
{
	[methods release];
  	[categories release];
	[properties release];
	[parent release];
	[name release];
	[documentation release];
  	[super dealloc];
}

- (void) setupDocumentation
{
	documentation = [[NSMutableAttributedString alloc] initWithString:
		@"Write your class documentation here.\n\nWHAT DOES IT DO:\n\nWHY AND WITH WHICH COLLABORATORS OBJECTS:\n\nHOW DOES IT WORK:\n\n"];
}

- (id) initWithName: (NSString*) aName
{
	[self init];
	[self setName: aName];
	return self;
}

- (void) setAST: (LKSubclass*) aClassAST
{
	[aClassAST retain];
	[ast release];
	ast = aClassAST;
}

- (LKSubclass*) ast
{
	return ast;
}

- (void) setName: (NSString*) aName
{
	[aName retain];
	[name release];
	name = aName;
}

- (NSString*) name
{
	return name;
}

- (void) setDocumentation: (NSMutableAttributedString*) aDocumentation
{
	[documentation release];
	documentation = [aDocumentation copy];
}

- (NSMutableAttributedString*) documentation
{
	return documentation;
}

- (void) addMethod: (ModelMethod*) aMethod
{
	[methods addObject: aMethod];
	[self reloadCategories];
}

- (void) removeMethod: (ModelMethod*) aMethod
{
	[methods removeObject: aMethod];
	[self reloadCategories];
}

- (void) addProperty: (NSString*) aProperty
{
	[properties addObject: aProperty];
}

- (NSMutableArray*) properties
{
	return properties;
}

- (NSMutableArray*) methods
{
	return methods;
}

- (void) removeCategory: (NSString*) categoryName
{
	NSMutableArray* category = [categories objectForKey: categoryName];
	if (category)
	{
		for (int i=0; i<[category count]; i++)
		{
			ModelMethod* method = [category objectAtIndex: i];
			[method setCategory: nil];
		}
		[categories removeObjectForKey: categoryName];
		[self reloadCategories];
	}
}

- (NSMutableArray*) setCategory: (NSString*) categoryName
{
	NSMutableArray* category = [categories objectForKey: categoryName];
	if (category == nil) 
	{
		category = [NSMutableArray new];
		[categories setObject: category forKey: categoryName];
		[category release];
	}
	return category;
}

- (void) reloadCategories
{
	NSArray* keys = [categories allKeys];
	for (int i=0; i<[keys count]; i++)
	{
		NSString* key = [keys objectAtIndex: i];
		NSMutableArray* category = [categories objectForKey: key];
		[category removeAllObjects];
	}
	NSMutableArray* all = [self setCategory: ALL];
	for (int i=0; i<[methods count]; i++)
	{
		ModelMethod* method = [methods objectAtIndex: i];
		NSString* categoryName = [method category];
		if ((categoryName == nil)
			|| (categoryName == ALL))
		{
			categoryName = AYU;
		}
		NSMutableArray* category = [self setCategory: categoryName];
		[category addObject: method];
		[all addObject: method];
	}
}

- (NSMutableArray*) sortedCategories
{
	NSMutableArray* list = [NSMutableArray new];
	NSArray* keys = [categories allKeys];
	for (int i=0; i<[keys count]; i++)
	{
		NSString* key = [keys objectAtIndex: i];
		if (key != ALL && key != AYU)
		{
			[list addObject: key];
		}
	}

	if ([categories objectForKey: AYU])
 	{
		[list insertObject: AYU atIndex: 0];
	}
	[list insertObject: ALL atIndex: 0];

	return [list autorelease];
}

- (NSMutableDictionary*) categories
{
	return categories;
}

- (BOOL) hasMethodWithSignature: (NSString*) aSignature
{
	for (int i=0; i<[methods count]; i++)
	{
		ModelMethod* method = [methods objectAtIndex: i];
		if ([[method signature] isEqualToString: aSignature])
		{
			return YES;
		}
	}
	return NO;
}

- (ModelMethod*) methodWithSignature: (NSString*) aSignature
{
	for (int i=0; i<[methods count]; i++)
	{
		ModelMethod* method = [methods objectAtIndex: i];
		if ([[method signature] isEqualToString: aSignature])
		{
			return method;
		}
	}
	return nil;
}

- (NSString*) representation
{
	NSMutableString* content = [NSMutableString new];
	[content appendString: 
		[NSString stringWithFormat: @"%@ subclass: %@\n[", parent, name]];
	if ([properties count] > 0) {
		[content appendString: @"| "];
		for (int i=0; i<[properties count]; i++)
		{
			NSString* property = [properties objectAtIndex: i];
			[content appendString: [NSString stringWithFormat: @"%@ ", property]];
		}
		[content appendString: @"|"];
	}
	for (int i=0; i<[methods count]; i++)
	{
		ModelMethod* method = [methods objectAtIndex: i];
		[content appendString: @"\n"];
		[content appendString: [method representation]];
	}
	[content appendString: @"\n]"];

	return [content autorelease];
}

- (NSString*) dynamicRepresentation
{
	NSMutableString* content = [NSMutableString new];
	for (int i=0; i<[methods count]; i++)
	{
		[content appendString: 
			[NSString stringWithFormat: @"\n%@ extend [", name]];
		ModelMethod* method = [methods objectAtIndex: i];
		NSString* rep = [method representation];
		NSLog (@"method rep <%@>", rep);
		if (rep != nil && [rep length]) {
			[content appendString: @"\n"];
			[content appendString: [method representation]];
		}
		[content appendString: @"\n]"];
	}

	return [content autorelease];
}

@end
