#import <Cocoa/Cocoa.h>
#import <EtoileFoundation/EtoileFoundation.h>
#include <time.h>
#import <SourceCodeKit/SourceCodeKit.h>

int main(int argc, char **argv)
{
	if (argc != 2)
	{
		fprintf(stderr, "usage: %s {source file}\n", argv[0]);
	}
	[NSAutoreleasePool new];
	NSString *fileName = [NSString stringWithUTF8String: argv[1]];
	SCKSourceCollection *collection = [SCKSourceCollection new];
	SCKSourceFile *file = [collection sourceFileForPath: fileName];
	NSString *sourceString = [NSString stringWithContentsOfFile: fileName];
	NSMutableAttributedString *source = [[NSMutableAttributedString alloc] initWithString: sourceString];
	SCKSyntaxHighlighter *highlighter = [SCKSyntaxHighlighter new];
	file.source = source;
	[file addIncludePath: @"."];
	[file addIncludePath: @"/usr/local/include"];
	[file addIncludePath: @"/usr/local/GNUstep/Local/Library/Headers"];
	[file addIncludePath: @"/usr/local/GNUstep/System/Library/Headers"];

	clock_t c1 = clock();
	[file reparse];
	[file syntaxHighlightFile];
	clock_t c2 = clock();
	NSLog(@"Syntax highlighting took %f seconds.  .",
			((double)c2 - (double)c1) / (double)CLOCKS_PER_SEC);
	c1 = clock();
	[highlighter transformString: source];
	c2 = clock();
	NSLog(@"Syntax highlighting took %f seconds.  .",
			((double)c2 - (double)c1) / (double)CLOCKS_PER_SEC);

	[highlighter release];
	fileName = [fileName stringByDeletingPathExtension];
	fileName = [fileName stringByAppendingPathExtension: @"rtf"];

	[[source RTFFromRange: NSMakeRange(0, [source length]) documentAttributes: 0] writeToFile: fileName atomically: NO];
	//NSLog(@"Source Tree: %@", sourceTree);
}
