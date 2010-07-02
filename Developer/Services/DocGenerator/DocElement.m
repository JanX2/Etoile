//
//  GSDocBlock.m
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "DocElement.h"
#import "HtmlElement.h"
#import "Parameter.h"

@implementation DocElement

- (id) init
{
	SUPERINIT;
	rawDescription = [NSMutableString new];
	return self;
}

- (void) dealloc
{
	[rawDescription release];
	[filteredDescription release];
	[name release];
	[super dealloc];
}

- (NSString *) name
{
	return name;
}

- (void) setName: (NSString *)aName
{
	ASSIGN(name, aName);
}

- (void) appendToRawDescription: (NSString *)aDescription
{
	[rawDescription appendString: aDescription];
}

- (NSString *) rawDescription
{
	return rawDescription;
}

- (NSString *) filteredDescription
{
	return filteredDescription;
}

- (void) setFilteredDescription: (NSString *)aDescription
{
	ASSIGN(filteredDescription, aDescription);
}

- (void) addInformationFrom: (DescriptionParser *)aParser
{
	[self setFilteredDescription: [aParser description]];
}

- (HtmlElement *) htmlDescription
{
	return [[HtmlElement new] autorelease];
}

@end


@implementation DocSubroutine

- (id) init
{
	SUPERINIT;
	parameters = [NSMutableArray new];
	task = [[NSString alloc] initWithString: @"Default"];
	return self;
}

- (void) dealloc
{
	[parameters release];
	[task release];
	[task release];
	[returnType release];
	[super dealloc];
}

- (NSString *) description
{
	return [NSString stringWithFormat: @"%@ - %@, %@", [super description], 
			name, [self task]];
}

- (NSString *) task
{
	return task;
}

- (void) setTask: (NSString *)aTask
{
	ASSIGN(task, aTask);
}

- (void) setReturnType: (NSString *) aReturnType
{
	ASSIGN(returnType, aReturnType);
}

- (void) addParameter: (NSString *)aName ofType: (NSString *)aType
{
	//  [parameters addObject: [NSDictionary dictionaryWithObjectsAndKeys: aName, @"name", aType, @"type", nil]];
	[parameters addObject: [Parameter newWithName: aName andType: aType]];
}

@end

