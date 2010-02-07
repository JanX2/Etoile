/*
   Copyright (C) 2009 Nicolas Roard <nicolas@roard.com>

   This application is free software; you can redistribute it and/or
   modify it under the terms of the MIT license. See COPYING.
*/

#import <EtoileSerialize/EtoileSerialize.h>
#import "ModelMethod.h"
#import "ModelClass.h"

@implementation ModelMethod

- (BOOL) serialize: (char *)aVariable using: (ETSerializer *)aSerializer
{
	NSLog(@"model method serialize %s", aVariable);
	if (strcmp(aVariable, "ast")==0)
	{
		return YES;
	}
/*
    if (strcmp(aVariable, "code")==0)
	{
		NSLog(@"code class in ModelMethod: %@", [code class]);
		NSString* tmp = [code string];
		[aSerializer storeObjectFromAddress: &tmp withName: "code"];
		return YES;
	}
*/
	return [super serialize: aVariable using: aSerializer];
}

- (void *) deserialize: (char *)aVariable
           fromPointer: (void *)aBlob
               version: (int)aVersion
{
	if (strcmp(aVariable, "ast")==0)
	{
		ast = nil;
		return MANUAL_DESERIALIZE;
	}
	return AUTO_DESERIALIZE;
}
	
- (void) finishedDeserializing
{
	NSLog(@"Deserialized code string: %@", code);
//	NSMutableAttributedString* ncode = [[NSMutableAttributedString alloc] initWithString: (NSString *)code];
//	[self setCode: ncode];
}


- (id) init
{
	self = [super init];
	classMethod = NO;
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

- (void) setClassMethod: (BOOL) isClassMethod
{
	classMethod = isClassMethod;
}

- (BOOL) isClassMethod
{
	return classMethod;
}

- (void) setAST: (LKMethod*) aMethodAST
{
	[aMethodAST retain];
	[ast release];
	ast = aMethodAST;
}

- (LKMethod*) ast
{
	return ast;
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
	//[aSignature retain];
	[signature release];
	signature = [aSignature copy];
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
	NSArray* lines = [[code string] componentsSeparatedByString: @"\n"];
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
	if (classMethod)
	{
		return [NSString stringWithFormat: @"+ %@", signature];
	}
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

- (void) setCode: (NSAttributedString*) aCode
{
	[code release];
	code = [aCode copy];
//	[self parseCode];
}

- (NSAttributedString*) code
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
	[representation appendString: [code string]];
	[representation appendString: @"\n]\n"];
	return representation;
}

@end
