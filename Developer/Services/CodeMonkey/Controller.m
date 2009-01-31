/*
   Copyright (C) 2009 Nicolas Roard <nicolas@roard.com>

   This application is free software; you can redistribute it and/or
   modify it under the terms of the MIT license. See COPYING.
*/

#import <AppKit/AppKit.h>
#import <LanguageKit/LanguageKit.h>
#import <EtoileUI/EtoileUI.h>
#import "Controller.h"
#import "ModelClass.h"
#import "ModelMethod.h"
#import "ASTModel.h"
#import "ASTReplace.h"
#import "ASTTransform.h"

@interface LKAST (pretty)
- (NSMutableAttributedString*) prettyprint;
@end

@implementation Controller

- (void) awakeFromNib
{
	[self setTitle: @"Classes" for: classesList];
	[self setTitle: @"Categories" for: categoriesList];
	[self setTitle: @"Methods" for: methodsList];

	[infoPanel setBackgroundColor: [NSColor blackColor]];
	[infoVersion setStringValue: @"v 0.1"];
	[infoVersion setTextColor: [NSColor whiteColor]];
	[infoAuthors setStringValue: @"(c) 2009 Nicolas Roard. Art from digitalart (flickr)"];
	[infoAuthors setTextColor: [NSColor whiteColor]];

	[propertiesList setDataSource: self];
	[propertiesList setDelegate: self];
	[propertiesList setAutoresizesAllColumnsToFit: YES];

	[self setTitle: @"Properties" for: propertiesList];
	[codeTextView setTextContainerInset: NSMakeSize(8,8)];
	[codeTextView setDelegate: self];

	doingPrettyPrint = NO;
	newStatement = NO;
	quotesOpened = NO;
	[self showClassDetails];
	[self update];


	//NSString* test = @"NSObject subclass: CalcEngine [ | a b | run [ | c | a := 'hello'. b := 'plop'. c := a. ] ]";

	//[self loadContent: test];
	//[self loadFile: @"/home/nico/svn/etoile/yjchen/Calc/Calc.st"];
	//[self loadFile: @"/home/nico/svn/etoile/Etoile/Developer/Services/CodeMonkey/test.st"];
	//[self loadFile: @"/home/nico/svn/etoile/Etoile/Services/User/Melodie/ETPlaylist.st"];
	//[self loadFile: @"/home/nico/svn/etoile/Etoile/Services/User/Melodie/MusicPlayerController.st"];
	//[self loadFile: @"/home/nico/svn/etoile/Etoile/Services/User/Melodie/MelodieController.st"];
	//[LKCompiler compileString: test];
	//id obj = [NSClassFromString(@"Test") new];
	//NSLog (@"ivars: %@", [obj instanceVariableNames]);
	//[obj inspect: self];
}

- (void) loadFile: (NSString*) path
{
	NSString* fileContent = [NSString stringWithContentsOfFile: path];
	[self loadContent: fileContent];
}

- (void) loadContent: (NSString*) aContent
{
	id parser = [[[LKCompiler compilerForExtension: @"st"] parser] new];
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
		/*
		NSLog (@"reay to compile %@", classes);
		[ast compileWith: defaultJIT()];
		// We create instances so that categories can later be applied
		NSLog(@"all class compiled (%d)", [classes count]);
		for (int i=0; i<[classes count]; i++)
		{
			ModelClass* aClass = [classes objectAtIndex: i];
			Class theClass = NSClassFromString([aClass name]);
			NSLog (@"new class (%@)", theClass);
			id obj = [theClass new];
			[obj release];
		}
		*/
		[self update];
	NS_HANDLER
		NSLog (@"Exception %@", [localException reason]);
	NS_ENDHANDLER
	[parser release];
}

- (void) setTitle: (NSString*) title for: (NSTableView*) tv
{
	[[[[tv tableColumns] objectAtIndex: 0] headerCell] setStringValue: title];
}

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

- (void) swapContentViewWith: (NSView*) aView
{
	[currentView retain]; // removeFromSuperview release it..
	[currentView removeFromSuperview];
	currentView = aView;
	[currentView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	[content addSubview: currentView];
}

- (void) showClassDetails
{
	[self swapContentViewWith: [classContent contentView]];
}

- (void) showMethodDetails
{
	[self swapContentViewWith: [methodContent contentView]];
}

- (ModelClass*) currentClass
{
	int row = [classesList selectedRow];	
	if (row != -1 && [classes count] > row)
	{
		return [classes objectAtIndex: row];
	}
	return nil;
}

- (NSMutableArray*) currentCategory
{
	ModelClass* class = [self currentClass];
	if (class)
	{
		int row = [categoriesList selectedRow];
		if (row > -1)
		{
			id name = [[class sortedCategories] objectAtIndex: row];
			if (name)
			{
				return [[class categories] objectForKey: name];
			}
		}
	}
	return nil;
}

- (NSString*) currentCategoryName
{
	id class = [self currentClass];
	if (class)
	{
		int row = [categoriesList selectedRow];
		if (row > -1)
		{
			return [[class sortedCategories] objectAtIndex: row];
		}
	}
	return nil;
}

- (ModelMethod*) currentMethod
{
	id category = [self currentCategory];
	if (category)
	{
		int row = [methodsList selectedRow];
		if (row > -1)
		{
			return [category objectAtIndex: row];
		}
	}
	return nil;
}

- (void) update
{
	[classesList reloadData];
	[classesList sizeToFit];
	[categoriesList reloadData];
	[categoriesList sizeToFit];
	[methodsList reloadData];
	[methodsList sizeToFit];
	NSLog (@"propertyList, reloadData");
	[propertiesList reloadData];
	[propertiesList sizeToFit];
        if ([self currentMethod])
	{
		NSAttributedString* code = [[self currentMethod] code];
		//NSAttributedString* string = [[NSMutableAttributedString alloc] initWithString: code];
		//[[codeTextView textStorage] setAttributedString: string];
		[[codeTextView textStorage] setAttributedString: code];
		//[string release];
		NSString* signature = [[self currentMethod] signature];
		[signatureTextField setStringValue: signature];
	}
	if ([self currentClass])
	{
		NSAttributedString* string = [[self currentClass] documentation];
		[[classDocTextView textStorage] setAttributedString: string];
	}
	[self setStatus: @"Ready"];
}

// TableView delegate

- (void) tableViewSelectionDidChange: (NSNotification*) aNotification
{
	[self update];
}

- (BOOL) tableView: (NSTableView*) tv shouldSelectRow: (NSInteger) row
{
	if (tv == classesList)
	{
		[self showClassDetails];
	}
	if (tv == categoriesList)
	{
		[self showMethodDetails];
	}
	if (tv == methodsList)
	{
		[self showMethodDetails];
	}
	return YES;
}

// TableView source delegate

- (int) numberOfRowsInTableView: (NSTableView*) tv
{
	if (tv == classesList) 
	{
		return [classes count];
	}
	if (tv == categoriesList)
	{
		if ([self currentClass] != nil)
		{
			return [[[self currentClass] sortedCategories] count];
		}
	}
	if (tv == methodsList)
	{
		if ([self currentCategory] != nil)
		{
			return [[self currentCategory] count];
		}
	}
	if (tv == propertiesList)
	{
		if ([self currentClass] != nil)
		{
			return [[[self currentClass] properties] count];
		}
	}
	return 0;
}

- (id) tableView: (NSTableView*) tv objectValueForTableColumn: (NSTableColumn*) tc row: (NSInteger) row
{
	if (tv == classesList)
	{
		ModelClass* aClass = (ModelClass*) [classes objectAtIndex: row];
		return [aClass name];
	}	
	if (tv == categoriesList)
	{
		if ([self currentClass] != nil)
		{
			return [[[self currentClass] sortedCategories] objectAtIndex: row];
		}
	}
	if (tv == methodsList)
	{
		if ([self currentCategory] != nil)
		{
			return [[[self currentCategory] objectAtIndex: row] signature];
		}
	}
	if (tv == propertiesList)
	{
		if ([self currentClass] != nil)
		{
			if ([[[self currentClass] properties] count] > row)
			{
				return [[[self currentClass] properties] objectAtIndex: row];
			}
		}
	}
	return nil;
}

///////

- (void) addCategory: (id)sender
{
	[addCategoryNamePanel close];
	NSString* categoryName = [newCategoryNameField stringValue];

	if ([self currentClass] && [categoryName length] > 0)
	{
		[[self currentClass] setCategory: categoryName];
		[self update];
	}
}


- (void) addClass: (id)sender
{
  	[addClassNamePanel close];
  	NSString* className = [newClassNameField stringValue];
  	
	if ([className length] > 0) 
	{
  		ModelClass* aClass = [[ModelClass alloc] initWithName: className];
		[classes addObject: aClass];
		[aClass release];
		[self update];
	}
}


- (void) addMethod: (id)sender
{
	if ([self currentClass]) 
	{
		NSMutableAttributedString* code = [content textStorage];
		if ([code length] > 0)
		{
			ModelMethod* aMethod = [ModelMethod new];
			[aMethod setCode: code];
			[aMethod setCategory: [self currentCategoryName]];
			[[self currentClass] addMethod: aMethod];
			[aMethod release];
			[self update];
		}
		else
		{
			[self setStatus: @"We cannot add an empty method!"];
		}
	}
	else 
	{
		[self setStatus: @"No class selected: we cannot add the method."];
	}
}

- (void) addProperty: (id) sender
{
  	[addPropertyNamePanel close];
	ModelClass* class = [self currentClass];
	if (class)
	{
  		NSString* propertyName = [newPropertyNameField stringValue];
		NSLog (@"propertyName added: %@", propertyName);
		[class addProperty: propertyName];	
		[self showClassDetails];
		[self update];
	}
}

- (void) load: (id)sender
{
	NSOpenPanel* panel = [NSOpenPanel openPanel];
	[panel setAllowsMultipleSelection: NO];
	if ([panel runModalForTypes: [NSArray arrayWithObject: @"st"]] == NSOKButton) 
	{
		NSArray* files = [panel filenames];
		for (int i=0; i<[files count]; i++) 
		{
			[self loadFile: [files objectAtIndex: i]];
		}
	}
}


- (void) removeCategory: (id)sender
{
	if ([self currentClass] && [self currentCategoryName])
	{
		[[self currentClass] removeCategory: [self currentCategoryName]];
		[self update];
	}
}


- (void) removeClass: (id)sender
{
	int row = [classesList selectedRow];
	if (row > -1) 
	{
		[classes removeObjectAtIndex: row];
		[self update];
	}
}


- (void) removeMethod: (id)sender
{
	int row = [methodsList selectedRow];
	if (row > -1)
	{
		if ([self currentClass] != nil)
		{
			[[[self currentClass] methods] objectAtIndex: row];
			[self update];
		}
	}
}

- (void) removeProperty: (id)sender
{
}

- (void) saveToFile: (id)sender
{
	NSMutableString* output = [NSMutableString new];
	for (int i=0; i<[classes count]; i++)
	{
		ModelClass* class = [classes objectAtIndex: i];
		//NSString* representation = [class representation];
		NSString* representation = [[[class ast] prettyprint] string];
		NSLog (@"rep1: %@", representation);
		[output appendString: representation];
		[output appendString: @"\n\n"];
	}
	NSSavePanel* panel = [NSSavePanel savePanel];
	[panel setRequiredFileType: @"st"];
	if ([panel runModal] == NSFileHandlingPanelOKButton) 
	{
		NSLog(@" save file <%@>", [panel filename]);
		[output writeToFile: [panel filename] atomically: YES];	
	}

	[output release];
}

- (void) save: (id)sender
{
	if ([self currentClass]) 
	{
		NSMutableAttributedString* code = [codeTextView textStorage];
		if ([code length] > 0)
		{
			//NSString* signature = [ModelMethod extractSignatureFrom: code];
			//if ([signature isEqualToString: [[self currentMethod] signature]])

			
			NSString* signature = [signatureTextField stringValue];
			NSLog (@"save (%@) <%@>", signature, code);

			id compiler = [LKCompiler compilerForExtension: @"st"];
			id parser = [[[compiler parser] new] autorelease];
			NSLog (@"compiler %@", compiler);
			NSString* toParse = [NSString stringWithFormat: @"%@ [ %@ ]", signature, [code string]];
			NSLog(@"to parse: <%@>", toParse);
			NS_DURING
			LKAST* methodAST = [parser parseMethod: toParse];
			NSLog (@"method AST: %@", methodAST);
			NSLog (@"pretty print: %@", [[methodAST prettyprint] stringValue]);

			if ([[self currentClass] hasMethodWithSignature: signature])
			{
				ModelMethod* method = [[self currentClass] methodWithSignature: signature];
				[method setCode: [methodAST prettyprint]];
				//[[self currentMethod] setCode: code];
			}
			else // we add a new method
			{
				// TODO: refactor addMethod
				// FIXME: there is a crash if sig but no body
				ModelMethod* aMethod = [ModelMethod new];
				[aMethod setCode: code];
				[aMethod setSignature: signature];
				[aMethod setCategory: [self currentCategoryName]];
				[[self currentClass] addMethod: aMethod];
				[aMethod release];
			}
			[self update];
			NS_HANDLER
			NSLog (@"parse error...");
			NS_ENDHANDLER
		}
	}
	
	//Class myClass = NSClassFromString(@"MyTest");
	//NSLog (@"in save, class MyTest: %@", myClass);
	//NSLog (@"in save, class MyTest: %@ (%@)", myClass, myClass->super_class);
/*
        for (int i=0; i<[classes count]; i++)
	{
		ModelClass* class = [classes objectAtIndex: i];
		if ([[class methods] count] > 0) 
		{
			NSString* representation = [class representation];
			NSLog (@"Class representation: <%@>", representation);
			if (NSClassFromString([class name]) == nil)
			{
				if (![[LKCompiler compilerForLanguage: @"Smalltalk"] compileString: representation])
				{
					NSLog(@"error while compiling");
				}
			}
			else
			{
				NSString* dynamic = [class dynamicRepresentation];
				NSLog (@"dynamic compile <%@>", dynamic);
				if (![[LKCompiler compilerForLanguage: @"Smalltalk"] compileString: dynamic])
				{
					NSLog(@"error while compiling dynamically");
				}
			}
		}
	}
*/
}

- (void) runClass: (id) sender
{
	if ([self currentClass]) 
	{
		NS_DURING
		NSString* name = [[self currentClass] name];
		id instance = [NSClassFromString(name) new];
		[instance run];
		[instance release];
		NS_HANDLER
		NSLog (@"run Exception %@", [localException reason]);
		NS_ENDHANDLER
	}
}

- (void) setStatus: (NSString*) text
{
	[statusTextField setStringValue: text];
}

- (void) prettyPrint
{
	if ([self currentClass]) 
	{
		NSMutableAttributedString* code = [codeTextView textStorage];
		if ([code length] > 0)
		{
			NSString* signature = [signatureTextField stringValue];
			id compiler = [LKCompiler compilerForExtension: @"st"];
			id parser = [[[compiler parser] new] autorelease];
			NSString* toParse = [NSString stringWithFormat: @"%@ [ %@ ]", signature, [code string]];
			NS_DURING
				LKAST* methodAST = [parser parseMethod: toParse];
				[methodAST setParent: [[self currentClass] ast]];
				//[methodAST check];

				if ([[self currentClass] hasMethodWithSignature: signature])
				{
					ModelMethod* method = [[self currentClass] methodWithSignature: signature];
					[ASTReplace replace: [method ast] with: methodAST on: [[self currentClass] ast]];
					[method setAST: (LKMethod*)methodAST];
					[method setCode: [methodAST prettyprint]];
				}
				else // we add a new method
				{
					// TODO: refactor addMethod
					// FIXME: there is a crash if sig but no body
					ModelMethod* aMethod = [ModelMethod new];
					[aMethod setAST: (LKMethod*)methodAST];
					[aMethod setCode: code];
					[aMethod setSignature: signature];
					[aMethod setCategory: [self currentCategoryName]];
					[[self currentClass] addMethod: aMethod];
					[aMethod release];
				}
				[self update];
				[self setStatus: @"Valid code"];
			NS_HANDLER
				NSLog (@"exc: %@", [localException description]);
				[self setStatus: @"Invalid code"];
			NS_ENDHANDLER
		}
	}
}

- (void) textDidChange: (NSNotification*) aNotification
{
	if (doingPrettyPrint) {
		[self prettyPrint];
		doingPrettyPrint = NO;
		NSUInteger index = [[codeTextView textStorage] length] - cursorPosition;
		NSRange range = NSMakeRange(index, 0);
		[codeTextView setSelectedRange: range];
		if (newStatement) {
			NSMutableDictionary* attributes = [NSMutableDictionary new];
			[attributes setObject: [NSFont systemFontOfSize: 16] forKey: @"NSFontAttributeName"];
			[attributes setObject: [NSColor blackColor] forKey: @"NSForegroundColorAttributeName"];
			NSMutableAttributedString* rc = [[NSMutableAttributedString alloc]
				initWithString: @"\n" attributes: attributes];
			[[codeTextView textStorage] insertAttributedString: rc atIndex: index];
			[rc release];
			[attributes release];
			//	[[[NSMutableAttributedString alloc] initWithString: @"\n"] autorelease]
			//	atIndex: index];
			newStatement = NO;
		}
		if (quotesOpened) {
			quotesOpened = NO;
		}
	}
}

- (BOOL) textView: (NSTextView*) aTextView shouldChangeTextInRange: (NSRange) affectedRange replacementString: (NSString*) replacementString
{
	// Rather inefficient pretty-printer -- for every text modification, we parse the
	// entire content of the text view and we pretty-print the resulting AST (if valid).
	// We only call the pretty-printer when we insert a dot or hit return.
	//
	// TODO: When we'll have the LKToken pointing to the original text, we could use those
	// instead of using a string directly derivated from the AST.
	//
	BOOL quote = NO;
	if ([replacementString isEqualToString: @"\n"]) {
		newStatement = YES;
	}
	if ([replacementString isEqualToString: @"\""]) 
	{
		if (quotesOpened == NO)
			quotesOpened = YES;
		quote = YES;
	}
	if (newStatement || quote || [replacementString isEqualToString: @"."]) {
  		doingPrettyPrint = YES;
		NSUInteger length = [[codeTextView textStorage] length];
		// we store the cursor position, counting from the end of the string...
		// this way even if the reformatting insert new characters, we will 
		// still be able to set the cursor at the right position.
		cursorPosition = length - (affectedRange.location + affectedRange.length);
	}
	return YES;
}

@end
