/* All Rights reserved */

#include <AppKit/AppKit.h>
#include "TWDocument.h"
#include "TWTextView.h"
#include "TWCharacterPanel.h"
#include <OgreKit/OgreTextFinder.h>
#import <IDEKit/IDETextTypes.h>
#import <IDEKit/IDESyntaxHighlighter.h>


@implementation TWDocument

- (void) appendString: (NSString *) string
{
  [textView insertText: string];
}

- (void) characterSelectedInPanel: (id) sender
{
  NSString *character = [[[(TWCharacterPanel *)sender matrix] selectedCell] stringValue];
  [textView insertText: character];
}

- (void) awakeFromNib
{
  /* It is difficult to connect to textView in scroll view with Gorm */
  textView = [scrollView documentView];
  textFinder = [OgreTextFinder sharedTextFinder];
  [textFinder setTargetToFindIn: textView];

  // I agree on that. It's also difficult to connect from a textView.
  [textView setDelegate: self];

  [scrollView setHasHorizontalScroller: NO];
  [scrollView setHasVerticalScroller: YES];
  [textView setHorizontallyResizable: NO];
  [textView setVerticallyResizable: YES];
  [textView setFrameSize: [scrollView contentSize]];
}

- (void) windowControllerDidLoadNib: (NSWindowController *) windowController
{
  NSFont *font = [textView font];
  [[textView textStorage] setAttributedString: aString];
	highlighter.source = [textView textStorage];

	[highlighter addIncludePath: @"."];
	[highlighter addIncludePath: @"/usr/local/include"];
	[highlighter addIncludePath: @"/usr/local/GNUstep/Local/Library/Headers"];
	[highlighter addIncludePath: @"/usr/local/GNUstep/System/Library/Headers"];

	[highlighter reparse];
	[highlighter syntaxHighlightFile];
	[highlighter convertSemanticToPresentationMarkup];
  /* Make sure the font is monospace for plain text */
  /* FIXME: there are a couple issues I met:
   * 1. font may be nil from NSTextView at some point.
   * 2. not every font can be converted into monospace.
   * Therefore, font need to be get before setAttributedString:
   * and always use userFixedPitchFontOfSize:
   */
  if ([[self fileType] isEqualToString: @"TWPlainTextType"]) {
    font = [NSFont userFixedPitchFontOfSize: [font pointSize]];
    [textView setFont: font];
  }
}

- (NSString *) windowNibName
{
  return @"Document.gorm";
}

- (BOOL) loadDataRepresentation: (NSData *) data ofType: (NSString *) type
{
	if ([type isEqualToString: @"TWRTFTextType"])
	{
		ASSIGN(aString, AUTORELEASE([[NSAttributedString alloc] initWithRTF: data documentAttributes: NULL]));
	} 
	else if ([type isEqualToString: @"TWPlainTextType"])
	{
		NSString *s = [[NSString alloc] initWithData: data
		                                    encoding: [NSString defaultCStringEncoding]];
		[aString release];
		aString = [[NSAttributedString alloc] initWithString: s];
		[s release];
	}
	else if ([@"TWSourceCode" isEqualToString: type])
	{
		NSString *s = [[NSString alloc] initWithData: data
		                                    encoding: NSUTF8StringEncoding];
		[aString release];
		aString = [[NSAttributedString alloc] initWithString: s];
		[s release];

		[highlighter release];
		highlighter = [IDESyntaxHighlighter new];
		highlighter.fileName = @"Unnamed.m";
	}
  if (aString) {
    return YES;
  } else {
    return NO;
  }
}

- (NSData *) dataRepresentationOfType: (NSString *) type
{
  NSTextStorage *ts = [textView textStorage];
  if ([type isEqualToString: @"TWRTFTextType"]) {
    return [ts RTFFromRange: NSMakeRange(0, [ts length]) documentAttributes: nil];
  } else if ([type isEqualToString: @"TWPlainTextType"]) {
    return [[ts string] dataUsingEncoding: [NSString defaultCStringEncoding]];
  } else {
    return nil;
  }
}

- (NSFileWrapper *)fileWrapperRepresentationOfType:(NSString *)type
{
  if ([type isEqualToString: @"TWRTFDTextType"]) {
    NSTextStorage *ts = [textView textStorage];
    return [ts RTFDFileWrapperFromRange: NSMakeRange(0, [ts length])
	       documentAttributes: nil];
  } else {
    return [super fileWrapperRepresentationOfType: type];
  }
}

- (BOOL)loadFileWrapperRepresentation:(NSFileWrapper *)wrapper
                               ofType:(NSString *)type
{
	if ([type isEqualToString: @"TWRTFDTextType"])
	{
		aString = [[NSAttributedString alloc] initWithRTFDFileWrapper: wrapper documentAttributes: NULL];
		if (aString)
		{
		return YES;
		}
	}
	else if ([@"TWSourceCode" isEqualToString: type])
	{
		NSString *s = [[NSString alloc] initWithData: [wrapper regularFileContents]
		                                    encoding: NSUTF8StringEncoding];
		[aString release];
		aString = [[NSAttributedString alloc] initWithString: s];
		[s release];

		[highlighter release];
		highlighter = [IDESyntaxHighlighter new];
		highlighter.fileName = [wrapper filename];
		NSString *path = [[wrapper filename] stringByDeletingLastPathComponent];
		[highlighter addIncludePath: path];
		path = [path stringByAppendingPathComponent: @".."];
		path = [path stringByAppendingPathComponent: @"Headers"];
		[highlighter addIncludePath: path];
		return YES;
	}
	else 
	{
		return [super loadFileWrapperRepresentation: wrapper ofType: type];
	}
	return NO;
}

/* Printing */
- (void) printShowingPrintPanel: (BOOL)flag
{
	NSPrintOperation* po;

	po = [NSPrintOperation printOperationWithView: textView
	                                    printInfo: [self printInfo]];
	
	[po setShowPanels: flag];
	[po runOperation];
}

- (void) textDidChange: (NSNotification*) textObject
{
	[self updateChangeCount: NSChangeDone];
	[highlighter reparse];
	NSTextStorage *ts = [textView textStorage];
	NSString *str = [ts string];
	for (NSValue *selection in [textView selectedRanges])
	{
		NSUInteger start, end;
		[str getLineStart: &start
		              end: &end
		      contentsEnd: NULL
		         forRange: [selection rangeValue]];
		NSRange r = {start, end-start};
		[highlighter syntaxHighlightRange: r];
	}
	[highlighter convertSemanticToPresentationMarkup];
}

/* Find panel */
- (void) showFindPanel: (id) sender
{
  [textFinder showFindPanel: sender]; 
}

- (void) showCharacterPanel: (id) sender
{
  [[TWCharacterPanel sharedCharacterPanel] orderFront: self];
}

@end
