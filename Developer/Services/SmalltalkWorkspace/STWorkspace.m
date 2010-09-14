#import <EtoileFoundation/EtoileFoundation.h>
#import <EtoileFoundation/ETTranscript.h>
#import <LanguageKit/LanguageKit.h>
#import "STWorkspace.h"

@implementation STWorkspace

- (void)awakeFromNib
{
  LKSymbolTable *table = [[LKMethodSymbolTable alloc] initWithLocals: nil
	                                                               args: nil];

	_interpreterContext = [[LKInterpreterContext alloc] initWithSymbolTable: table
	                                                                 parent: nil];
	[LKCompiler setDefaultDelegate: self];
	_parser = [[[[LKCompiler compilerForLanguage: @"Smalltalk"] parserClass] alloc] init];

  if (nil == _parser)
  {
    [[_textView window] makeKeyAndOrderFront: nil];
    NSBeginAlertSheet(@"Error loading Smalltalk",@"Ok",nil,nil,[_textView window],nil,nil,nil,nil,@"Ensure the Smalltalk bundle is in ~/Library/Bundles/LanguageKit/Smalltalk.bundle");
  }
}

- (void)dealloc
{
	DESTROY(_interpreterContext);
	DESTROY(_parser);
	[super dealloc];
}

- (NSString *)windowNibName
{
	return @"STWorkspace";
}

- (IBAction) doSelection: (id)sender
{
	[self runCode: [self selectedString]];
}

- (IBAction) printSelection: (id)sender
{
	NSString *printed = [[self runCode: [self selectedString]] description];
	NSLog(@"result: %@", printed);

	if (nil != printed)
	{
		// Insert the result after the code that was run
		NSRange codeRange = [self selectedRange];
		[_textView setSelectedRange:
			NSMakeRange(codeRange.location + codeRange.length, 0)];
		[_textView insertText: printed];

		// Select the inserted result
		[_textView setSelectedRange:
			NSMakeRange(codeRange.location + codeRange.length, [printed length])];
	}
}

/**
 * Returns the currently selected string, or the text between the start of the
 * last newline and the cursor if there is no selection.
 */
- (NSString *) selectedString
{
	return [[_textView string] substringWithRange: [self selectedRange]];
}

- (NSRange) selectedRange
{
	NSRange selectedRange = [_textView selectedRange];
	if (selectedRange.length == 0)
	{
		NSRange previousNewline = [[_textView string]
		    rangeOfCharacterFromSet: [NSCharacterSet newlineCharacterSet]
		                    options:  NSBackwardsSearch 
		                      range: NSMakeRange(0, selectedRange.location)];
		if (previousNewline.location == NSNotFound)
		{
			previousNewline.location = 0;
		}
		else
		{
			previousNewline.location++;
		}
		selectedRange = NSMakeRange(previousNewline.location, 
		    selectedRange.location - previousNewline.location);
	}
	return selectedRange;
}

- (id) runCode: (NSString *)code
{
	id result = nil;

	NSRange codeRange = [self selectedRange];
	// Select the bit after the code, so that the transcript will not overwrite anything
	[_textView setSelectedRange:
		NSMakeRange(codeRange.location + codeRange.length, 0)];

	LKMethod *method = [_parser parseMethod: 
		[NSString stringWithFormat: @"workspaceMethod [ %@ ]", code]];

	[method inheritSymbolTable: [_interpreterContext symbolTable]];

	// Make the last statement an implicit return
	NSMutableArray *statements = [method statements];
	if ([statements count] > 0)
	{
		if (![[statements lastObject] isKindOfClass: [LKReturn class]])
		{
			NSLog(@"Last object before: '%@'", [statements lastObject]);
			[statements replaceObjectAtIndex: [statements count] - 1
			                      withObject: [LKReturn returnWithExpr: [statements lastObject]]];
			NSLog(@"Last object after: '%@'", [statements lastObject]);
		}
	}

	BOOL ok = [method check];

	NSLog(@"Parsed method: %@ check result: %d", method, ok);

	if (ok)
	{
		NSMutableDictionary *threadDict = [[NSThread currentThread] threadDictionary];
		id transcriptDelegate = [threadDict objectForKey: kTranscriptDelegate];


		[threadDict setObject: self forKey: kTranscriptDelegate];

		NS_DURING
			result = [method executeInContext: _interpreterContext];
		NS_HANDLER
			result = [NSString stringWithFormat: @"%@: %@", 
			   [localException name],
			   [localException reason]]; 
		NS_ENDHANDLER
		[threadDict setValue: transcriptDelegate forKey: kTranscriptDelegate];
	}

	// Reset the selection.
	[_textView setSelectedRange: codeRange];

	return result;
}

- (void)appendTranscriptString: (NSString*)aString
{
	[_textView insertText: aString];
}

@end

@implementation STWorkspace(CompilerDelegate)
- (BOOL)compiler: (LKCompiler*)aCompiler
generatedWarning: (NSString*)aWarning
         details: (NSDictionary*)info
{
	[self appendTranscriptString:
		[NSString stringWithFormat:@"Warning: %@",
		 [info valueForKey: kLKHumanReadableDescription]]];
	return YES;
}

- (BOOL)compiler: (LKCompiler*)aCompiler
  generatedError: (NSString*)anError
         details: (NSDictionary*)info
{
	LKAST *ast = [info valueForKey: kLKASTNode];

	// Assignment to undefined variables automatically creates a new variable
	if ([[ast parent] isKindOfClass: [LKAssignExpr class]] &&
	    ast == [(LKAssignExpr*)[ast parent] target] &&
	    [[ast symbols] scopeOfSymbol: [(LKDeclRef*)ast symbol]] == LKSymbolScopeInvalid)
	{
		[[_interpreterContext symbolTable] addSymbol: [(LKDeclRef*)ast symbol]];
		return YES;
	}

	[self appendTranscriptString:
	 [NSString stringWithFormat:@"Error: %@",
	  [info valueForKey: kLKHumanReadableDescription]]];
	return NO;
}

@end

