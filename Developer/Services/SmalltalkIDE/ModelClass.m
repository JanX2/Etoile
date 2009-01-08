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
	parent = [[NSString alloc] initWithString: @"NSObject"];
  	return self;
}

- (void) dealloc
{
	[methods release];
  	[categories release];
	[parent release];
	[name release];
	[documentation release];
  	[super dealloc];
}

- (id) initWithName: (NSString*) aName
{
	[self init];
	[self setName: aName];
	return self;
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

- (void) setDocumentation: (NSString*) aDocumentation
{
	[aDocumentation retain];
	[documentation release];
	documentation = aDocumentation;
}

- (NSString*) documentation
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

- (NSString*) representation
{
	NSMutableString* content = [NSMutableString new];
	[content appendString: 
		[NSString stringWithFormat: @"%@ subclass: %@\n[", name, parent]];
	for (int i=0; i<[methods count]; i++)
	{
		ModelMethod* method = [methods objectAtIndex: i];
		[content appendString: @"\n"];
		[content appendString: [method representation]];
	}
	[content appendString: @"\n]"];

	return [content autorelease];
}

@end
