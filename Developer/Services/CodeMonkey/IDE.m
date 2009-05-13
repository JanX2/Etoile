/*
   Copyright (C) 2009 Nicolas Roard <nicolas@roard.com>

   This application is free software; you can redistribute it and/or
   modify it under the terms of the MIT license. See COPYING.
*/

#import <AppKit/AppKit.h>
#import <LanguageKit/LanguageKit.h>
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

- (id) init
{
	self = [super init];
	classes = [NSMutableArray new];
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
	withCategory: (NSString*) categoryName
	onClass: (ModelClass*) aClass
{
	ModelMethod* aMethod = [ModelMethod new];
	[aMethod setCode: code];
	[aMethod setCategory: categoryName];
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

@end
