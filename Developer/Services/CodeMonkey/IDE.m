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


@implementation IDE

#ifdef COREOBJECT
static COProxy* MyCOProxy;
#endif

- (id) init
{
	self = [super init];
	classes = [NSMutableArray new];
#ifdef COREOBJECT
	self = [COProxy proxyWithObject: self];
	MyCOProxy = (COProxy*)self;
	[self setPersistencyMethodNames: A(@"replaceMethod:withSignature:andCode:onClass:",
                                           @"addMethod:withSignature:withCategory:onClass:",
                                           @"addClassMethod:withSignature:withCategory:onClass:",
                                           @"addClass:",
                                           @"addCategory:onClass:",
                                           @"addProperty:onClass:",
                                           @"loadContent:")];
#endif
	return self;
}

- (void) dealloc
{
	[classes release];
	[super dealloc];
}

- (ModelClass*) classForName: (NSString*) aClassName
{
	for (int i=0; i<[classes count]; i++) {
		if ([[[classes objectAtIndex: i] name] isEqualToString: aClassName]) {
			return [classes objectAtIndex:i ];
		}
	}
        return nil;
}

- (void) removeClassAtIndex: (int) row
{
	[[self classes] removeObjectAtIndex: row];
}

- (BOOL) serialize: (char *)aVariable using: (ETSerializer *)aSerializer
{
        NSLog(@"IDE serialize %s", aVariable);
        return [super serialize: aVariable using: aSerializer];
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
        NSLog(@"class %@ added", className);
        NSLog(@"current nb of classes: %d", [classes count]);
	//NSLog(@"current object version %d", [(COProxy*)[IDE default] objectVection]);
}

- (void) addCategory: (NSString*) categoryName onClass: (NSString*) aClassName
{
	ModelClass* aClass = [self classForName: aClassName];
	[aClass setCategory: categoryName];
}

- (void) addMethod: (NSMutableAttributedString*) code 
	withSignature: (NSString*) signature
	withCategory: (NSString*) categoryName
	onClass: (NSString*) aClassName
{
	NSLog(@"SHOULD BE PROXIED ADD METHOD!");
	ModelClass* aClass = [self classForName: aClassName];
	NSLog(@"(%x) addMethod: %@ withSignature: %@ on class %@", self, code, signature, aClass);
	if (aClass == nil) return;
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
	NSLog(@"should have finished the addMethod");
}

- (void) addClassMethod: (NSMutableAttributedString*) code 
	withSignature: (NSString*) signature
	withCategory: (NSString*) categoryName
	onClass: (NSString*) aClassName
{
	ModelClass* aClass = [self classForName: aClassName];
        if (aClass == nil) return;
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

- (void) addProperty: (NSString*) propertyName onClass: (NSString*) aClassName
{
	ModelClass* aClass = [self classForName: aClassName];
	[aClass addProperty: propertyName];
}

- (NSMutableString*) allClassesContent
{
	NSMutableString* output = [NSMutableString new];
        NSLog(@"%d classes found", [classes count]);
	for (int i=0; i<[classes count]; i++)
	{
		ModelClass* class = [classes objectAtIndex: i];
		NSString* representation = [class representation];
                NSLog(@"representation %@", representation); 
		id compiler = [LKCompiler compilerForLanguage: @"Smalltalk"];
		id parser = [[[compiler parserClass] new] autorelease];
		LKAST* ast = [parser parseString: representation];
                NSLog(@"parsing done");
		[output appendString: [[ast prettyprint] string]];
		//NSString* rep = [[[class ast] prettyprint] string];
		//NSLog (@"rep1: %@", rep);
		//[output appendString: rep];
		[output appendString: @"\n\n"];
	}
        NSLog(@"end of allClassesContent: %@", output);
	return [output autorelease];
}

- (void) replaceMethod: (NSString*) methodSignature
	withSignature: (NSString*) signature
	andCode: (NSString*) code
	onClass: (NSString*) aClassName
{
	ModelClass* aClass = [self classForName: aClassName];
	if (aClass == nil) return;
	ModelMethod* method = [aClass methodWithSignature: methodSignature];
        NSLog(@"replace Method");
	id compiler = [LKCompiler compilerForLanguage: @"Smalltalk"];
	id parser = [[[compiler parserClass] new] autorelease];
	NSString* toParse = [NSString stringWithFormat: @"%@ [ %@ ]", signature, code];
	LKAST* methodAST = [parser parseMethod: toParse];
	[methodAST setParent: [aClass ast]];
	[ASTReplace replace: [method ast] with: methodAST on: [aClass ast]];
	[method setAST: (LKMethod*)methodAST];
	[method setCode: [methodAST prettyprint]];
NSLog(@"replace method");
#ifdef COREOBJECT
	NSLog(@"VERSION %d", [MyCOProxy objectVersion]);
#endif
}

@end
