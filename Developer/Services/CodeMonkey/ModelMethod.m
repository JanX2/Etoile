/*
   Copyright (C) 2009 Nicolas Roard <nicolas@roard.com>

   This application is free software; you can redistribute it and/or
   modify it under the terms of the MIT license. See COPYING.
*/

#import "ModelMethod.h"
#import "ModelClass.h"

@implementation ModelMethod

- (id) init
{
	self = [super init];
  	return self;
}

- (void) dealloc
{
	[signature release];
	[documentation release];
	[code release];
	[content release];
  	[super dealloc];
}

- (void) setClass: (ModelClass*) aClass
{
	[aClass retain];
	[class release];
	class = aClass;
}

- (ModelClass*) class
{
	return class;
}

- (void) setSignature: (NSString*) aSignature
{
	[aSignature retain];
	[signature release];
	signature = aSignature;
}

+ (NSString*) extractSignatureFrom: (NSString*) string
{
	NSArray* lines = [string componentsSeparatedByString: @"\n"];
	if ([lines count] > 0) 
	{
		NSString* line = [[lines objectAtIndex: 0]
			stringByTrimmingCharactersInSet:
				[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		return line;
	}
	return nil;
}

- (void) parseCode
{
	// Extract the signature from the code.
	NSArray* lines = [code componentsSeparatedByString: @"\n"];
	if ([lines count] > 0) {
		NSString* line = [[lines objectAtIndex: 0]
			stringByTrimmingCharactersInSet:
				[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		[self setSignature: line];
	}

	[content release];
	content = [NSMutableString new];
	for (int i=1; i<[lines count]; i++)
	{
		[content appendString: [lines objectAtIndex: i]];
	}
}


- (NSString*) signature
{
	return signature;
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

- (void) setCode: (NSString*) aCode
{
	[code release];
	code = [aCode copy];
	[self parseCode];
}

- (NSString*) code
{
	return code;
}

- (void) setCategory: (NSString*) aCategory
{
	[aCategory retain];
	[category release];
	category = aCategory;
	[class reloadCategories];
}

- (NSString*) category
{
	return category;
}

- (NSString*) representation
{
	NSMutableString* representation = [NSMutableString new];
	[representation appendString: 
		[NSString stringWithFormat: @"%@ [\n", signature]];
	[representation appendString: content];
	[representation appendString: @"\n]\n"];
	return representation;
}

@end
