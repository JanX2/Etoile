/*
   Copyright (C) 2009 Nicolas Roard <nicolas@roard.com>

   This application is free software; you can redistribute it and/or
   modify it under the terms of the MIT license. See COPYING.
*/

#import <AppKit/AppKit.h>
#import <LanguageKit/LanguageKit.h>
#import <EtoileUI/EtoileUI.h>
#import <CoreObject/CoreObject.h>
#import "Controller.h"
#import "ModelApplication.h"
#import "ModelClass.h"
#import "ModelMethod.h"
#import "ASTModel.h"
#import "ASTReplace.h"
#import "ASTTransform.h"
#import "IDE.h"

@interface LKAST (pretty)
- (NSMutableAttributedString*) prettyprint;
@end

@protocol GormServer
- (void) addClass: (NSDictionary *)dict;
@end

@implementation Controller

- (void) awakeFromNib
{
//	NSLog (@"mainWindow: %@", mainWindow);
//	[mainWindow makeMainWindow];
	[self setTitle: @"Classes" for: classesList];
	[self setTitle: @"Categories" for: categoriesList];
	[self setTitle: @"Methods" for: methodsList];

	[infoPanel setBackgroundColor: [NSColor blackColor]];
	[infoVersion setStringValue: @"v 0.2"];
	[infoVersion setTextColor: [NSColor whiteColor]];
	[infoAuthors setStringValue: @"(c) 2009,2010 Nicolas Roard. Art from digitalart (flickr)"];
	[infoAuthors setTextColor: [NSColor whiteColor]];

	[historySlider setAllowsTickMarkValuesOnly: YES];

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

- (void) generateBundle: (id) sender
{
	NSSavePanel* panel = [NSSavePanel savePanel];
	[panel setRequiredFileType: @"app"];
	if ([panel runModal] == NSFileHandlingPanelOKButton) 
	{
		NSLog(@" save file <%@>", [panel filename]);
		[[[IDE default] application] setPath: [panel filename]];
		[[[IDE default] application] generateAppBundle]; 
/*

		NSFileManager* fm = [NSFileManager defaultManager];
		[fm createDirectoryAtPath: [panel filename] attributes: nil];
		NSString* executable = [[[panel filename] lastPathComponent] stringByDeletingPathExtension];
		NSString* mainPath = [NSString stringWithFormat: @"%@/%@", [panel filename], executable];
		NSString* edlc = @"#!/bin/sh\nedlc -b `dirname $0`";
		[edlc writeToFile: mainPath atomically: YES];
		[fm changeFileAttributes: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: 511] forKey: NSFilePosixPermissions] atPath: mainPath];
		NSString* rscPath = [NSString stringWithFormat: @"%@/Resources", [panel filename]];
		[fm createDirectoryAtPath: rscPath attributes: nil];
		NSMutableString* lkclasses = [NSMutableString stringWithString: @"{\nSources = ("];
		NSArray* classes = [[IDE default] classes];
		NSString* principalClass = nil;
		for (int i=0; i<[classes count]; i++) {
		    ModelClass* class = [classes objectAtIndex: i];
	            NSMutableString* output = [NSMutableString new];
		    NSString* representation = [class representation];
		    id compiler = [LKCompiler compilerForLanguage: @"Smalltalk"];
		    id parser = [[[compiler parserClass] new] autorelease];
		    LKAST* ast = [parser parseString: representation];
		    [output appendString: [[ast prettyprint] string]];
		    NSString* fileName = [NSString stringWithFormat: @"%@/Resources/%@.st", [panel filename], [class name]];
		    [output writeToFile: fileName atomically: YES];
		    if (i>0)
			[lkclasses appendString: @", "];
		    [lkclasses appendString: [NSString stringWithFormat: @"\"%@.st\"", [class name]]];
		    if (i==0)
			principalClass = [NSString stringWithString: [class name]];
		}
		[lkclasses appendString: [NSString stringWithFormat: @");\nPrincipalClass=%@;\n}", principalClass]];
		NSString* lkclassesPath = [NSString stringWithFormat: @"%@/Resources/LKInfo.plist", [panel filename]];
		[lkclasses writeToFile: lkclassesPath atomically: YES];

		NSString* infoGnustepPath = [NSString stringWithFormat: @"%@/Resources/Info-gnustep.plist", [panel filename]];
		NSString* infoGnustepContent = [NSString stringWithFormat: 
			@"{ NSExecutable=\"%@\"; NSPrincipalClass=%@; NSMainNibFile=test; }", executable, principalClass];
		[infoGnustepContent writeToFile: infoGnustepPath atomically: YES]; 
*/
	}
}

- (void) loadFile: (NSString*) path
{
	NSString* fileContent = [NSString stringWithContentsOfFile: path];
	[[IDE default] loadContent: fileContent];
	[self update];
}

- (void) setTitle: (NSString*) title for: (NSTableView*) tv
{
	[[[[tv tableColumns] objectAtIndex: 0] headerCell] setStringValue: title];
}

- (id) init
{
	self = [super init];
	return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (void) swapContentViewWith: (NSView*) aView
{

	[currentView retain]; // removeFromSuperview release it..
	[currentView removeFromSuperview];
	currentView = aView;
	[currentView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	[currentView setFrameOrigin: NSMakePoint(0, 0)];
	[currentView setFrameSize: [content bounds].size];
	[content addSubview: currentView];
	[content setNeedsDisplay: YES];
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
	if (row != -1 && [[[IDE default] classes] count] > row)
	{
		return [[[IDE default] classes] objectAtIndex: row];
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
		// check that we are selecting something, and
                // that we are not showing the properties
		if ((row > -1) && ([categoriesList selectedRow] > 0))
		{
			return [category objectAtIndex: row];
		}
	}
	return nil;
}

static id <GormServer> GormProxy = nil;

- (void) updateGorm
{
    if (GormProxy == nil) {
        GormProxy = [[NSConnection rootProxyForConnectionWithRegisteredName:@"GormServer" host:nil] retain];
	//[GormProxy setProtocolForProxy:@protocol(GormServer)];
    }

    NSArray* classes = [[IDE default] classes];
    for (int i=0; i<[classes count]; i++) {
        NSMutableDictionary* sClass = [NSMutableDictionary new];
	ModelClass* class = [classes objectAtIndex: i];
        [sClass setObject: [class name] forKey: @"className"];
	[sClass setObject: [class parent] forKey: @"superClass"];
	NSArray* properties = [class properties];
	NSLog(@"properties: %@", properties);
	[sClass setObject: properties forKey: @"outlets"];
	[sClass setObject: [class actions] forKey: @"actions"];
	NSDictionary* toSend = [NSDictionary dictionaryWithDictionary: sClass];
	[GormProxy addClass: toSend];
        [sClass release];
    } 
}

- (void) update
{
        NSLog(@"update");
	[self updateHistory];
	[classesList reloadData];
	[classesList sizeToFit];
	[categoriesList reloadData];
	[categoriesList sizeToFit];
	[methodsList reloadData];
	[methodsList sizeToFit];
	[nibsList reloadData];
	[nibsList sizeToFit];
	[self updateGorm];
        NSLog(@"update done");

	// If we have a selected method, show it
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

        // If we have a selected class, set its class comment
	if ([self currentClass])
	{
		NSAttributedString* string = [[self currentClass] documentation];
		[[classDocTextView textStorage] setAttributedString: string];
	}


	[self setStatus: @"Ready"];
        NSLog(@"end of update");
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
	
		if (row > 0) // methods, not properties
		{
			[self setTitle: @"Methods" for: methodsList];
		}
		else
		{
			[self setTitle: @"Properties" for: methodsList];
		}
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
		int ret = [[[IDE default] classes] count];
                NSLog(@"nb classes: %d", ret);
                return ret;
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
			int ret = [[self currentCategory] count];
			NSLog(@"display %d methods", ret);
			return ret;
		}
	}
	if (tv == nibsList)
	{
		return [[[[IDE default] application] nibs] count];
	}
	return 0;
}

- (id) tableView: (NSTableView*) tv objectValueForTableColumn: (NSTableColumn*) tc row: (NSInteger) row
{
	if (tv == classesList)
	{
		ModelClass* aClass = (ModelClass*) [[[IDE default] classes] objectAtIndex: row];
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
		        if ([categoriesList selectedRow] > 0) // methods, not properties
			{
				return [[[self currentCategory] objectAtIndex: row] signature];
			}
			else
			{
				return [[self currentCategory] objectAtIndex: row];
			}
		}
	}
	if (tv == nibsList)
	{
		return [[[[IDE default] application] nibs] objectAtIndex: row];
	}
	return nil;
}

- (void) tableView: (NSTableView *)tv
    setObjectValue: (id)anObject
    forTableColumn: (NSTableColumn *)tc
               row: (int)rowIndex
{
	if (tv == nibsList)
	{
	        int selected = [nibsList selectedRow];
		[[[IDE default] application] renameNibAtIndex: selected withName: anObject];
	}
}

#ifdef COREOBJECT

- (void) updateHistory
{
	COProxy *proxy = (COProxy *)[IDE default];
	if ([proxy objectVersion] > 0) {
		[historyTextField setIntValue: [proxy objectVersion]];
		[historySlider setIntValue: [proxy objectVersion]];
	}
}

- (void) changeHistory: (id)sender
{
	NSLog(@"Slider changed to %d", [historySlider intValue]);
	if ([[IDE default] objectVersion] == [historySlider intValue]) return;
	COProxy *proxy = (COProxy *)[IDE default];
	NSLog(@"changeHistory, IDE1 %p", [[IDE default] _realObject]);
	[proxy restoreObjectToVersion: [historySlider intValue]];
	NSLog(@"changeHistory, IDE2 %p", [[IDE default] _realObject]);

	//NSLog(@"changeHistory, IDE3 %p", [[IDE default] _realObject]);
	//[historyTextField setIntValue:
	//	[historySlider intValue]];

	for (int i=0; i<[[[IDE default] classes] count]; i++) {
		id cls = [[[IDE default] classes] objectAtIndex: i];
		[cls reloadCategories];
		NSLog(@"class %d (%p) is: %@", i, cls, [cls representation]);
	}
	[self update];
}

- (void) setHistory: (id)sender
{
	NSLog(@"Set history to %d",  [historyTextField intValue]);
	COProxy *proxy = (COProxy *)[IDE default];
	[proxy restoreObjectToVersion: [historyTextField intValue]];
	//[historySlider setIntValue: [historyTextField intValue]];
	[self update];
}
#endif

- (void) addCategory: (id)sender
{
	[addCategoryNamePanel close];
	NSString* categoryName = [newCategoryNameField stringValue];

	if ([self currentClass] && [categoryName length] > 0)
	{
		[[IDE default] addCategory: categoryName onClass: [[self currentClass] name]];
		[self update];
	}
}


- (void) addClass: (id)sender
{
  	[addClassNamePanel close];
  	NSString* className = [newClassNameField stringValue];
  	
	if ([className length] > 0) 
	{
		[[IDE default] addClass: className];
		[self update];
	}
}


- (void) addInstanceMethod: (id)sender
{
	[self addMethod: YES];
}

- (void) addClassMethod: (id)sender
{
	[self addMethod: NO];
}

- (void) addMethod: (BOOL)isInstanceMethod
{
	NSLog(@"addmethod %d", isInstanceMethod);
	if ([self currentClass]) 
	{
		NSMutableAttributedString* code = [content textStorage];
		if ([code length] > 0)
		{
			NSString* signature = [signatureTextField stringValue];
			if (isInstanceMethod)
			{
				[[IDE default]
					addMethod: code
					withSignature: signature
					withCategory: [self currentCategoryName]
					onClass: [[self currentClass] name]];
			}
			else
			{
				[[IDE default]
					addClassMethod: code
					withSignature: signature
					withCategory: [self currentCategoryName]
					onClass: [[self currentClass] name]];
			}
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
		[[IDE default] addProperty: propertyName onClass: [class name]];
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
                [[IDE default] removeClassAtIndex: row];
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
	NSSavePanel* panel = [NSSavePanel savePanel];
	[panel setRequiredFileType: @"st"];
	if ([panel runModal] == NSFileHandlingPanelOKButton) 
	{
		NSLog(@" save file <%@>", [panel filename]);
	        NSMutableString* output = [[IDE default] allClassesContent];
                NSLog(@" classes content %@", output);
		[output writeToFile: [panel filename] atomically: YES];	
	}
}

- (void) save: (id)sender
{
	[self recreateMethodAST];
	return;
	if ([self currentClass]) 
	{
		NSMutableAttributedString* code = [codeTextView textStorage];
		if ([code length] > 0)
		{
			//NSString* signature = [ModelMethod extractSignatureFrom: code];
			//if ([signature isEqualToString: [[self currentMethod] signature]])

			
			NSString* signature = [signatureTextField stringValue];
			NSLog (@"save (%@) <%@>", signature, code);

			id compiler = [LKCompiler compilerForLanguage: @"Smalltalk"];
			id parser = [[[compiler parserClass] new] autorelease];
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

/**
 * This parse the currently-edited method and generate its AST.
 * The new AST then replace the old one in the class.
 */
- (void) recreateMethodAST
{
	NSLog(@"recreateMethodAST");
	if ([self currentClass]) 
	{
		NSMutableAttributedString* code = [codeTextView textStorage];
		if ([code length] > 0)
		{
			NSString* signature = [signatureTextField stringValue];
			NS_DURING
				if ([[self currentClass] hasMethodWithSignature: signature])
				{
					[[IDE default] replaceMethod: signature
						withSignature: signature
						andCode: [code string]
						onClass: [[self currentClass] name]];
				}
				else // we add a new method
				{
					// TODO: refactor addMethod
					// FIXME: there is a crash if sig but no body
                                        NSLog(@" we add a new method: %@ %@", code, [code class]);
				        [[IDE default]
					    addMethod: code
					    withSignature: signature
					    withCategory: [self currentCategoryName]
					    onClass: [[self currentClass] name]];
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

#define _max(x,y) ((x)>(y)?(x):(y))
/**
 * We use the textDidChange: hook to pretty-print the code:
 * - we regenerate the code's AST
 * - we use the AST to create a pretty-printed version of the code's attributed string
 * - we finally replace the current attributed string with the new one
 */
- (void) textDidChange: (NSNotification*) aNotification
{
	// We are modifying the codeTextView's attributed string
	if (doingPrettyPrint) {
		[self recreateMethodAST];
                NSLog(@"we recreated the ast");
		doingPrettyPrint = NO;
		NSUInteger index = [[codeTextView textStorage] length] - cursorPosition;
		NSRange range = NSMakeRange(index, 0);
		[codeTextView setSelectedRange: range];
		if (newStatement) {
			NSMutableDictionary* attributes = [NSMutableDictionary new];
			[attributes setObject: [NSFont systemFontOfSize: 12] forKey: @"NSFontAttributeName"];
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

	
#ifdef COREOBJECT
        NSLog(@"in textdidchange, before the proxy call");
	COProxy *proxy = (COProxy *)[IDE default];
	int maxValue = _max([proxy objectVersion], [historySlider intValue]);
        NSLog(@"max value for the versions: %d (object version %d)", maxValue, [proxy objectVersion]);
	[historySlider setMinValue: 0];
	[historySlider setMaxValue: maxValue];
	[historySlider setNumberOfTickMarks: maxValue]; 
	[historySlider setIntValue: [proxy objectVersion]];

	[historyTextField setIntValue: [proxy objectVersion]];
#endif
}

- (void) redisplayAST
{

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

- (void) addNib: (id) sender
{
	NSLog(@"addNib");
	[[[IDE default] application] addNib];
	[self update];
}

- (void) removeNib: (id) sender
{
	int selected = [nibsList selectedRow];
	[[[IDE default] application] removeNibAtIndex: selected];
	[self update];
}

- (void) editNibInGorm: (id) sender
{
	int selected = [nibsList selectedRow];
	[[[IDE default] application] editNibAtIndex: selected];
}

- (void) markNibAsMainNib: (id) sender
{
	int selected = [nibsList selectedRow];
	[[[IDE default] application] makeMainNibAtIndex: selected];
}

@end
