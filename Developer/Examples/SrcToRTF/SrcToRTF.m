#import <Cocoa/Cocoa.h>
#import <EtoileFoundation/EtoileFoundation.h>
#include <time.h>
#import <IDEKit/IDETextTypes.h>
#import <IDEKit/IDESyntaxHighlighter.h>

int main(int argc, char **argv)
{
	if (argc != 2)
	{
		fprintf(stderr, "usage: %s {source file}\n", argv[0]);
	}
	[NSAutoreleasePool new];
	NSString *fileName = [NSString stringWithUTF8String: argv[1]];
	IDESyntaxHighlighter *highlighter = [IDESyntaxHighlighter new];
	NSString *sourceString = [NSString stringWithContentsOfFile: fileName];
	NSMutableAttributedString *source = [[NSMutableAttributedString alloc] initWithString: sourceString];
	highlighter.source = source;
	highlighter.fileName = fileName;
	[highlighter addIncludePath: @"."];
	[highlighter addIncludePath: @"/usr/local/include"];
	[highlighter addIncludePath: @"/usr/local/GNUstep/Local/Library/Headers"];
	[highlighter addIncludePath: @"/usr/local/GNUstep/System/Library/Headers"];

	clock_t c1 = clock();
	[highlighter reparse];
	[highlighter syntaxHighlightFile];
	clock_t c2 = clock();
	NSLog(@"Syntax highlighting took %f seconds.  .",
			((double)c2 - (double)c1) / (double)CLOCKS_PER_SEC);
	c1 = clock();
	[highlighter convertSemanticToPresentationMarkup];
	c2 = clock();
	NSLog(@"Syntax highlighting took %f seconds.  .",
			((double)c2 - (double)c1) / (double)CLOCKS_PER_SEC);

	[highlighter release];
	fileName = [fileName stringByDeletingPathExtension];
	fileName = [fileName stringByAppendingPathExtension: @"rtf"];

	[[source RTFFromRange: NSMakeRange(0, [source length]) documentAttributes: 0] writeToFile: fileName atomically: NO];
	//NSLog(@"Source Tree: %@", sourceTree);
}
