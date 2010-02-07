/*
   Copyright (C) 2009 Nicolas Roard <nicolas@roard.com>

   This application is free software; you can redistribute it and/or
   modify it under the terms of the MIT license. See COPYING.
*/

#import <LanguageKit/LanguageKit.h>
#import <EtoileSerialize/EtoileSerialize.h>
#import "IDE.h"
#import "ModelClass.h"
#import "ModelMethod.h"

static NSString* PROPERTIES = @"-- Properties --";
static NSString* ALL = @"-- All --";
static NSString* AYU = @"<< As yet Undefined >>";
static int INSTANCE_VIEW = 0;
static int CLASS_VIEW = 1;

@interface GSTextStorage : NSTextStorage
{
  NSString              *_textChars;
  NSMutableArray        *_infoArray;
}
@end

@implementation GSTextStorage (serialize)
- (BOOL) serialize: (char *)aVariable using: (ETSerializer *)aSerializer
{
        NSLog(@"GS serialize %s", aVariable);
        if (strcmp(aVariable, "_infoArray")==0)
	{
		NSLog(@"not serializing _infoArray");
		return YES;
	}
        if (strcmp(aVariable, "_textChars")==0)
	{
        	return [super serialize: aVariable using: aSerializer];
	}
	return YES;
}

- (void*) deserialize:(char*)aVariable fromPointer:(void*)aBlob version:(int)aVersion
{
        NSLog(@"GS deserialize %s", aVariable);
        return [super deserialize: aVariable fromPointer: aBlob version: aVersion];
}

- (void) finishedDeserializing
{
	NSLog(@"finished deserializing GSTextStorage");
	NSString* str = [_textChars retain];
	NSLog(@"code stored: %@", str);
	[self initWithString: str];
	[str release];
	NSLog(@"code after deserialization: %@", self);
}
@end

@implementation ModelClass

- (BOOL) serialize: (char *)aVariable using: (ETSerializer *)aSerializer
{
        NSLog(@"Model class serialize %s", aVariable);

	if (strcmp(aVariable, "name")==0)
	{
		// Just for debugging
		NSLog(@"Serialize class name: %@", name);
	}

	if (strcmp(aVariable, "methods")==0)
	{
		// Just for debugging
		NSLog(@"Serialize class methods: %@", methods);
	}
	
	if (strcmp(aVariable, "ast")==0)
	{
		return YES;
	}
	if (strcmp(aVariable, "documentation")==0)
	{
		NSString* tmp = [documentation string];
		[aSerializer storeObjectFromAddress: &tmp withName: "documentation"];
		return YES;
	}
	return [super serialize: aVariable using: aSerializer];
}

- (void*) deserialize:(char*)aVariable fromPointer:(void*)aBlob version:(int)aVersion
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
	NSLog(@"Deserialized class parent: %@", parent);
	NSLog(@"Deserialized class name: %@", name);

	NSLog(@"Deserialized class documentation: %@", documentation);
	documentation = [[NSMutableAttributedString alloc] initWithString: (NSString*)documentation];
	NSLog(@"Deserialized methods: %@", methods);
	for (int i=0; i < [methods count]; i++) {
		NSLog(@"Deserialized method %d is: %@", i, 
			[methods objectAtIndex: i]);
	}
	
	[self generateAST];
}



+ (NSString*) PROPERTIES
{	
	return PROPERTIES;
}

- (id) init
{
	self = [super init];
	methods = [NSMutableArray new];
  	categories = [NSMutableDictionary new]; 
	properties = [NSMutableArray new];
	parent = [[NSString alloc] initWithString: @"NSObject"];
	[self setupDocumentation];
  	return self;
}

- (void) dealloc
{
	[methods release];
  	[categories release];
	[properties release];
	[parent release];
	[name release];
	[documentation release];
  	[super dealloc];
}

- (void) setupDocumentation
{
	documentation = [[NSMutableAttributedString alloc] initWithString:
		@"Write your class documentation here.\n\nWHAT DOES IT DO:\n\nWHY AND WITH WHICH COLLABORATORS OBJECTS:\n\nHOW DOES IT WORK:\n\n"];
}

- (id) initWithName: (NSString*) aName
{
	[self init];
	[self setName: aName];
	return self;
}

- (void) setAST: (LKSubclass*) aClassAST
{
	//NSLog (@"SET AST IN CLASS: %@", [[aClassAST prettyprint] string]);
	[aClassAST retain];
	[ast release];
	ast = aClassAST;
}

- (LKSubclass*) ast
{
	return ast;
}

- (void) generateAST
{
	id compiler = [LKCompiler compilerForLanguage: @"Smalltalk"];
	id parser = [[[compiler parserClass] new] autorelease];
	NSLog (@"representation: <%@>", [self representation]);
	NSLog (@"representation ast: <%@>", [parser parseString: [self representation]]);
	LKSubclass* classAST = (LKSubclass*) [parser parseString: [self representation]];
	[self setAST: classAST];
}

- (NSArray*) actions
{
	NSMutableArray* actions = [NSMutableArray new];
	for (int i=0; i<[methods count]; i++) {
		ModelMethod* method = [methods objectAtIndex: i];
		NSString* sig = [NSString stringWithString: [method signature]];
		NSLog (@"sig: <%@>", sig);
		NSArray* components = [sig componentsSeparatedByString: @" "];
		NSMutableString* finalSig = [NSMutableString new];
		for (int j=0; j<[components count]; j++) {
			NSString* component = [components objectAtIndex: j];
			NSLog(@"component: <%@>", component);
			if ([component hasSuffix: @":"]) {
				[finalSig appendString: component];
			}
		}
		if ([finalSig length]) {
			[actions addObject: finalSig];
		}
		[finalSig autorelease];
		NSLog(@"%@ -> sig: %@ => finalSig %@", [self name], sig, finalSig);
	}
	return [actions autorelease];
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

- (NSString*) parent
{
	return parent;
}

- (void) setDocumentation: (NSMutableAttributedString*) aDocumentation
{
	[documentation release];
	documentation = [aDocumentation copy];
}

- (NSMutableAttributedString*) documentation
{
	return documentation;
}

- (void) addMethod: (ModelMethod*) aMethod
{
	if ([self methodWithSignature: [aMethod signature]]) return;
	NSLog(@"Adding method on the class: %@", aMethod);
	[methods addObject: aMethod];
	[self reloadCategories];
	NSLog(@"(%x) representation: %@", self, [self representation]);
	NSLog(@"IDE is %x", [[IDE default] _realObject]);
	for (int i=0; i<[[[IDE default] classes] count]; i++) {
		id cls = [[[IDE default] classes] objectAtIndex: i];
		NSLog(@"in addMethod, class %d (%x) is: %@", i, cls, [cls representation]);
	}
}

- (void) removeMethod: (ModelMethod*) aMethod
{
	[methods removeObject: aMethod];
	[self reloadCategories];
}

- (void) addProperty: (NSString*) aProperty
{
	[properties addObject: aProperty];
	[self reloadCategories];
}

- (NSMutableArray*) properties
{
	return properties;
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
	[categories removeAllObjects];
	[[self setCategory: ALL] removeAllObjects];
	[[self setCategory: AYU] removeAllObjects];

	NSMutableArray* all = [self setCategory: ALL];
	NSLog(@"reload all %d", [all count]);
	for (int i=0; i<[methods count]; i++)
	{
		ModelMethod* method = [methods objectAtIndex: i];
		NSString* categoryName = [method category];
		if ((categoryName == nil)
			|| ([categoryName isEqualToString: ALL]))
		{
			categoryName = AYU;
		}
		NSMutableArray* category = [self setCategory: categoryName];
		[category addObject: method];
		[all addObject: method];
	}
	NSLog(@"reload catg, %d, %d methods", [all count], [methods count]);
	NSMutableArray* props = [self setCategory: PROPERTIES];
	[props removeAllObjects];
	for (int i=0; i<[properties count]; i++)
	{
		NSString* property = [properties objectAtIndex: i];
		[props addObject: property];
	}
}

- (NSMutableArray*) sortedCategories
{
	NSMutableArray* list = [NSMutableArray new];
	NSArray* keys = [categories allKeys];
	for (int i=0; i<[keys count]; i++)
	{
		NSString* key = [keys objectAtIndex: i];
		if (key != ALL && key != AYU && key != PROPERTIES)
		{
			[list addObject: key];
		}
	}

	if ([categories objectForKey: AYU])
 	{
		[list insertObject: AYU atIndex: 0];
	}
	[list insertObject: ALL atIndex: 0];
	[list insertObject: PROPERTIES atIndex: 0];

	return [list autorelease];
}

- (NSMutableDictionary*) categories
{
	return categories;
}

- (BOOL) hasMethodWithSignature: (NSString*) aSignature
{
	for (int i=0; i<[methods count]; i++)
	{
		ModelMethod* method = [methods objectAtIndex: i];
		if ([[method signature] isEqualToString: aSignature])
		{
			return YES;
		}
	}
	return NO;
}

- (ModelMethod*) methodWithSignature: (NSString*) aSignature
{
	for (int i=0; i<[methods count]; i++)
	{
		ModelMethod* method = [methods objectAtIndex: i];
		if ([[method signature] isEqualToString: aSignature])
		{
			return method;
		}
	}
	return nil;
}

- (NSString*) representation
{
	NSMutableString* content = [NSMutableString new];
	[content appendString: 
		[NSString stringWithFormat: @"%@ subclass: %@\n[", parent, name]];
	if ([properties count] > 0) {
		[content appendString: @"| "];
		for (int i=0; i<[properties count]; i++)
		{
			NSString* property = [properties objectAtIndex: i];
			[content appendString: [NSString stringWithFormat: @"%@ ", property]];
		}
		[content appendString: @"|"];
	}
	for (int i=0; i<[methods count]; i++)
	{
		ModelMethod* method = [methods objectAtIndex: i];
		[content appendString: @"\n"];
		if ([method isClassMethod])
		{
			[content appendString: @"+"];
		}
		[content appendString: [method representation]];
	}
	[content appendString: @"\n]"];

	return [content autorelease];
}

- (NSString*) dynamicRepresentation
{
	NSMutableString* content = [NSMutableString new];
	for (int i=0; i<[methods count]; i++)
	{
		[content appendString: 
			[NSString stringWithFormat: @"\n%@ extend [", name]];
		ModelMethod* method = [methods objectAtIndex: i];
		NSString* rep = [method representation];
		NSLog (@"method rep <%@>", rep);
		if (rep != nil && [rep length]) {
			[content appendString: @"\n"];
			[content appendString: [method representation]];
		}
		[content appendString: @"\n]"];
	}

	return [content autorelease];
}

@end
