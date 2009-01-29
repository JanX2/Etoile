/*
   Copyright (C) 2009 Nicolas Roard <nicolas@roard.com>

   This application is free software; you can redistribute it and/or
   modify it under the terms of the MIT license. See COPYING.
*/

#import <AppKit/AppKit.h>
#import <LanguageKit/LanguageKit.h>
#import "ASTModel.h"
#import "ModelClass.h"
#import "ModelMethod.h"

@interface LKMethod (pretty)
- (NSMutableAttributedString*) prettyprint;
@end

@implementation ASTModel
- (id) init
{
	self = [super init];
	classes = [NSMutableDictionary new];
	return self;
}
- (void) dealloc
{
	[classes release];
	[super dealloc];
}
- (NSMutableDictionary*) classes
{
	return classes;
}
- (LKAST*) visitASTNode: (LKAST*) aNode
{
	NSLog (@"node <%@> (%@)", aNode, [aNode class]);
	if ([aNode class] == [LKInstanceMethod class]) 
	{
		LKMethod* method = (LKMethod*) aNode;
		//NSLog(@"pretty: <%@>", [method prettyprint]);	
		//LKSubclass* class = (LKSubclass*) [method parent];

		NSLog(@"Instance Method: {%@}", [method description]);
		NSLog(@"Instance parent: {%@}", [method parent]);
		NSLog(@"Class: %@ (%@)", currentClass, [currentClass classname]);
		NSLog(@"pretty: <%@>", [method prettyprint]);	

		ModelClass* aClass = [classes objectForKey: [currentClass classname]];
		if (aClass == nil) 
		{
			aClass = [[ModelClass alloc] initWithName: [currentClass classname]];
			[classes setObject: aClass forKey: [currentClass classname]];
			[aClass autorelease];
		}
	
		ModelMethod* aMethod = [ModelMethod new];
		[aMethod setAST: method];
		[aMethod setCode: [method prettyprint]];
		//[aMethod parseCode];
		[aMethod setSignature: [[method signature] description]];
		[aClass addMethod: aMethod];
		[aMethod release];
		currentMethod = aMethod;
	} 
	else if ([aNode class] == [LKSubclass class])
	{
		LKSubclass* class = (LKSubclass*) aNode;
		currentClass = class;

		ModelClass* aClass = [classes objectForKey: [class classname]];
		[aClass setAST: class];
		if (aClass == nil) 
		{
			aClass = [[ModelClass alloc] initWithName: [class classname]];
			[classes setObject: aClass forKey: [class classname]];
			[aClass autorelease];
		}
		NSArray* ivars = [class ivars];
		for (int i=0; i<[ivars count]; i++)
		{
			NSString* ivar = [ivars objectAtIndex: i];
			[aClass addProperty: ivar];
		}
	}
	else
	{
		//NSLog (@"node <%@> (%@)", aNode, [aNode class]);
	}

	return aNode;
}
@end

