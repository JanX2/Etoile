/*
   Copyright (C) 2009 Nicolas Roard <nicolas@roard.com>

   This application is free software; you can redistribute it and/or
   modify it under the terms of the MIT license. See COPYING.
*/

#import <AppKit/AppKit.h>
#import <SmalltalkKit/SmalltalkKit.h>
#import <LanguageKit/LanguageKit.h>
#import "ASTModel.h"
#import "ModelClass.h"
#import "ModelMethod.h"

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
	if ([aNode class] == [LKInstanceMethod class]) 
	{
		LKMethod* method = (LKMethod*) aNode;
		LKSubclass* class = (LKSubclass*) [method parent];
		NSLog(@"Instance Method: {%@}", [method description]);
		NSLog(@"Class: (%@)", [class classname]);
	
		ModelClass* aClass = [classes objectForKey: [class classname]];
		if (aClass == nil) {
			aClass = [[ModelClass alloc] initWithName: [class classname]];
			[classes setObject: aClass forKey: [class classname]];
			[aClass autorelease];
		}
	
		ModelMethod* aMethod = [ModelMethod new];
		[aMethod setCode: [method methodBody]];
		//[aMethod parseCode];
		[aMethod setSignature: [[method signature] description]];
		[aClass addMethod: aMethod];
		[aMethod release];
		currentMethod = aMethod;
	} 
	else if ([aNode class] == [LKSubclass class])
	{
		LKSubclass* class = (LKSubclass*) aNode;
		ModelClass* aClass = [classes objectForKey: [class classname]];
		if (aClass == nil) {
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

