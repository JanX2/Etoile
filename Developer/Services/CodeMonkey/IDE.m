/*
   Copyright (C) 2009 Nicolas Roard <nicolas@roard.com>

   This application is free software; you can redistribute it and/or
   modify it under the terms of the MIT license. See COPYING.
*/

#import <AppKit/AppKit.h>
#import <LanguageKit/LanguageKit.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import <CoreObject/CoreObject.h>
#import <EtoileUI/EtoileUI.h>
#import "Controller.h"
#import "IDE.h"
#import "ModelClass.h"
#import "ModelMethod.h"
#import "ASTModel.h"
#import "ASTReplace.h"
#import "ASTTransform.h"

@interface LKAST (pretty)
- (NSMutableAttributedString*) prettyprint;
@end

@interface IDE (COProxy)
- (void) setPersistencyMethodNames: (NSArray *)names;
- (unsigned int) objectVersion;
@end

@implementation IDE

static COProxy* MyCOProxy;

- (id) init
{
	self = [super init];
	classes = [NSMutableArray new];
	self = [COProxy proxyWithObject: self];
	MyCOProxy = (COProxy*)self;
	[self setPersistencyMethodNames: A(@"replaceMethod:with:onClass:")];
	return self;
}

- (void) dealloc
{
	[classes release];
	[super dealloc];
}

+ (IDE*) default
{
	static id defaultIDE;
	if (defaultIDE == nil) {
		defaultIDE = [IDE new];
	}
	return defaultIDE;
}

- (NSMutableArray*) classes
{
	return classes;
}

- (void) loadContent: (NSString*) aContent
{
	id parser = [[[LKCompiler compilerForLanguage: @"Smalltalk"] parserClass] new];
	LKAST* ast;
	NS_DURING
		ast = [parser parseString: aContent];
		//[ast visitWithVisitor: [ASTTransform new]];
		ASTModel* model = [ASTModel new];
		NSLog (@"*** Model visitor ***");
		[ast visitWithVisitor: model];
		NSLog (@"model: <%@>", model);
		NSMutableDictionary* readClasses = [model classes];
		NSLog (@"classes: <%@>", readClasses);
		NSArray* keys = [readClasses allKeys];
		for (int i=0; i<[keys count]; i++)
		{
			NSString* key = [keys objectAtIndex: i];
			[classes addObject: [readClasses objectForKey: key]];
		}
		//[LKCompiler setDebugMode: YES];
		//NSLog (@"reay to compile %@", classes);
		//[ast compileWith: defaultJIT()];
		// We create instances so that categories can later be applied
		//NSLog(@"all class compiled (%d)", [classes count]);
		//for (int i=0; i<[classes count]; i++)
		//{
		//	ModelClass* aClass = [classes objectAtIndex: i];
		//	Class theClass = NSClassFromString([aClass name]);
		//	NSLog (@"new class (%@)", theClass);
		//	id obj = [theClass new];
		//	[obj release];
		//}
		//[self update];
	NS_HANDLER
		NSLog (@"Exception %@", [localException reason]);
	NS_ENDHANDLER
	[parser release];
}

- (void) addClass: (NSString*) className
{
	ModelClass* aClass = [[ModelClass alloc] initWithName: className];
	[aClass generateAST];
	[classes addObject: aClass];
	[aClass release];
}

- (void) addCategory: (NSString*) categoryName onClass: (ModelClass*) aClass
{
	[aClass setCategory: categoryName];
}

- (void) addMethod: (NSMutableAttributedString*) code 
	withSignature: (NSString*) signature
	withCategory: (NSString*) categoryName
	onClass: (ModelClass*) aClass
{
	ModelMethod* aMethod = [ModelMethod new];
	[aMethod setCode: code]; 
        [aMethod setSignature: signature];
	[aMethod setCategory: categoryName];

	id compiler = [LKCompiler compilerForLanguage: @"Smalltalk"];
	id parser = [[[compiler parserClass] new] autorelease];
	NSString* toParse = [NSString stringWithFormat: @"%@ [ %@ ]", signature, [code string]];
	LKAST* methodAST = [parser parseMethod: toParse];
	[methodAST setParent: [aClass ast]];
        [aMethod setAST: (LKMethod*)methodAST];

	[aClass addMethod: aMethod];
	[aMethod release];
}

- (void) addClassMethod: (NSMutableAttributedString*) code 
	withSignature: (NSString*) signature
	withCategory: (NSString*) categoryName
	onClass: (ModelClass*) aClass
{
	ModelMethod* aMethod = [ModelMethod new];
	[aMethod setClassMethod: YES];
	[aMethod setCode: code];
        [aMethod setSignature: signature];
	[aMethod setCategory: categoryName];

	id compiler = [LKCompiler compilerForLanguage: @"Smalltalk"];
	id parser = [[[compiler parserClass] new] autorelease];
	NSString* toParse = [NSString stringWithFormat: @"%@ [ %@ ]", signature, [code string]];
	LKAST* methodAST = [parser parseMethod: toParse];
	[methodAST setParent: [aClass ast]];
        [aMethod setAST: (LKMethod*)methodAST];

	[aClass addMethod: aMethod];
	[aMethod release];
}

- (void) addProperty: (NSString*) propertyName onClass: (ModelClass*) aClass
{
	[aClass addProperty: propertyName];
}

- (NSMutableString*) allClassesContent
{
	NSMutableString* output = [NSMutableString new];
	for (int i=0; i<[classes count]; i++)
	{
		ModelClass* class = [classes objectAtIndex: i];
		NSString* representation = [class representation];
		id compiler = [LKCompiler compilerForLanguage: @"Smalltalk"];
		id parser = [[[compiler parserClass] new] autorelease];
		LKAST* ast = [parser parseString: representation];
		[output appendString: [[ast prettyprint] string]];
		/*
		NSString* representation = [[[class ast] prettyprint] string];
		NSLog (@"rep1: %@", representation);
		[output appendString: representation];
		*/
		[output appendString: @"\n\n"];
	}
	return [output autorelease];
}

- (void) replaceMethod: (ModelMethod*) method 
	withSignature: (NSString*) signature
	andCode: (NSString*) code
	onClass: (ModelClass*) aClass
{
	id compiler = [LKCompiler compilerForLanguage: @"Smalltalk"];
	id parser = [[[compiler parserClass] new] autorelease];
	NSString* toParse = [NSString stringWithFormat: @"%@ [ %@ ]", signature, code];
	LKAST* methodAST = [parser parseMethod: toParse];
	[methodAST setParent: [aClass ast]];
	[ASTReplace replace: [method ast] with: methodAST on: [aClass ast]];
	[method setAST: (LKMethod*)methodAST];
	[method setCode: [methodAST prettyprint]];
	NSLog(@"VERSION %d", [MyCOProxy objectVersion]);
}

@end
