/*
   Copyright (C) 2009 Nicolas Roard <nicolas@roard.com>

   This application is free software; you can redistribute it and/or
   modify it under the terms of the MIT license. See COPYING.
*/

#import <AppKit/AppKit.h>
#import <SmalltalkKit/SmalltalkKit.h>
#import <LanguageKit/LanguageKit.h>
#import "ASTTransform.h"
#import "ModelClass.h"
#import "ModelMethod.h"

@implementation ASTTransform
- (LKAST*) visitASTNode: (LKAST*) aNode
{
	//NSLog (@"node <%@> (%@)", aNode, [aNode class]);
	if ([aNode class] == [LKAssignExpr class]) 
	{
		LKMessageSend* msg = [LKMessageSend message: @"setValue:"];
		LKAssignExpr* exp = (LKAssignExpr*) aNode;
		LKAST* parent = [exp parent];
		LKAST* expression = [exp expression];
		[msg addArgument: expression];
		[msg addSelectorComponent: @"forKey:"];
		LKStringLiteral* key = [LKStringLiteral literalFromString: [[exp target] symbol]];
		[msg addArgument: key];
		LKDeclRef* _self = [LKDeclRef reference: @"self"];
		[msg setTarget: _self];
		[msg setParent: parent];
		[msg check];
		return msg;
	}
	return aNode;
}
@end
