#import <EtoileFoundation/EtoileFoundation.h>
#import <LanguageKit/LanguageKit.h>
#import "STWorkspace.h"

@implementation STWorkspace

- (id)init
{
    SUPERINIT;
    _interpreterContext = 
      [[LKInterpreterContext alloc] initWithSelf: nil
                                         symbols: [NSArray array]
                                          parent: nil];
    [LKCompiler setDefaultDelegate: self];
    _parser = [[[[LKCompiler compilerForLanguage: @"Smalltalk"] parserClass] alloc] init];
    
    return self;
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
  [self runCode: [self selection]];
}

- (IBAction) printSelection: (id)sender
{
  NSString *printed = [[self runCode: [self selection]] description];
  NSLog(@"result: %@", printed);  
  [_textView setSelectedRange:
    NSMakeRange([_textView selectedRange].location + [_textView selectedRange].length, 0)];
  [_textView insertText: printed];
  [_textView setSelectedRange:
    NSMakeRange([_textView selectedRange].location, [printed length])];
}

/**
 * Returns the currently selected string, or the text between the start of the
 * last newline and the cursor if there is no selection.
 */
- (NSString *) selection
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
  return [[_textView string] substringWithRange: selectedRange];
}

- (id) runCode: (NSString *)code
{
  LKMethod *method = [_parser parseMethod: 
    [NSString stringWithFormat: @"workspaceMethod [ %@ ]", code]];
    
  NSMutableArray *statements = [method statements];
  
  // Make the last statement an implicit return
  if ([statements count] > 0)
  {
    if (![[statements lastObject] isKindOfClass: [LKReturn class]])
    {
      [statements replaceObjectAtIndex: [statements count] - 1
                            withObject: [LKReturn returnWithExpr: [statements lastObject]]];
    }
  }

  BOOL ok = [method check];
 
  NSLog(@"Method: %@ ok %d", method, ok);
  id result = [method executeInContext: _interpreterContext];

  return result;
}

@end

// FIXME: Report errors to the workspace window or a transcript window

@implementation STWorkspace(CompilerDelegate)

- (BOOL)compiler: (LKCompiler*)aCompiler
generatedWarning: (NSString*)aWarning
         details: (NSDictionary*)info
{
  NSLog(@"Warning %@ %@", aWarning, info);
  return YES;
}

- (BOOL)compiler: (LKCompiler*)aCompiler
  generatedError: (NSString*)anError
         details: (NSDictionary*)info
{
  LKAST *ast = [info valueForKey: kLKASTNode];
  if ([[ast parent] isKindOfClass: [LKAssignExpr class]] &&
      ast == [[ast parent] target])
  {
    NSLog(@"FIXME: Assign to %@", [info valueForKey:kLKHumanReadableDescription]);
    return NO;
  }
  NSLog(@"Error %@ %@", anError, info);
  return NO;
}

@end