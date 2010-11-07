#import "EtoileText.h"
#import <EtoileFoundation/EtoileFoundation.h>
#import "ETTeXHandlers.h"
#import <EtoileUI/NSObject+EtoileUI.h>
#import <SourceCodeKit/SourceCodeKit.h>

/**
 * Handle listings of the form:
 * \snippet{filename}{firstline}{lastline}
 */
@interface TRTeXImportNumberedListing : ETTeXHandler
{
	NSString *refType;
	NSString *filename;
	NSNumber *firstLine;
	NSNumber *lastLine;
}
@end
/**
 * Handle listings of the form:
 * \snippet{path}{filename}{firstline}{lastline}
 */
@interface TRTeXSystemSnippet : TRTeXImportNumberedListing
{
	NSString *path;
}
@end
/**
 * Handle listings of the form:
 * \snippet{filename}
 */
@interface TRTeXImportedListing : ETTeXHandler
{
	NSString *refType;
}
@end

/**
 * Handle keywords.  These are written in keyword style and also added to the
 * index.
 */
@interface TRTeXKeywordHandler : ETTeXHandler
{
	NSString *indexText;
	BOOL inOptArg;
}
@end
/**
 * Handle keyword abbreviation definitions from this command:
 * \keyabrv{keyword}{abbreviation}
 * These are written in the form:
 * keyword (abbreviation)
 * They are also added to the index as a cross reference.
 */
@interface TRTeXKeyabrvHandler : ETTeXHandler 
{
	NSString *phrase;
	NSString *abbreviation;
}
@end

/**
 * Handle \class{classname}.  Writes classname in code style and adds it to the index.
 */
@interface TRTeXClassHandler : ETTeXHandler @end
/**
 * A quick hack to parse \~{} as ~.  Does not work for the general case of
 * words requiring a tilde, but my TeX files are all UTF-8, so I don't need to
 * use the horrible TeX mechanisms of generating non-ASCII characters.
 */
@interface TRTeXTildeHack : ETTeXHandler @end



@implementation TRTeXImportNumberedListing
- (void)beginCommand: (NSString*)aCommand
{
	ASSIGN(refType, aCommand);
}
- (void)dealloc
{
	[refType release];
	[filename release];
	[firstLine release];
	[lastLine release];
	[super dealloc];
}
- (void)handleText: (NSString*)aString
{
	if (nil == filename)
	{
		ASSIGN(filename, aString);
	}
	else if (nil == firstLine)
	{
		ASSIGN(firstLine, [NSNumber numberWithInt: [aString intValue]]);
	}
	else if (nil == lastLine)
	{
		ASSIGN(lastLine, [NSNumber numberWithInt: [aString intValue]]);
		[[self root] endParagraph];
		[self.builder startNodeWithStyle: 
			[self.document typeFromDictionary: D(
				ETTextForeignImportType, kETTextStyleName,
				filename, kETTextSourceLocation,
				firstLine, kETTextFirstLine,
				lastLine, kETTextLastLine,
				refType, @"TRImportType")]];
		[self.builder endNode];
		self.scanner.delegate = self.parent;
	}
}
@end
@implementation TRTeXSystemSnippet 
- (void)dealloc
{
	[path release];
	[super dealloc];
}
- (void)handleText: (NSString*)aString
{
	if (nil == path)
	{
		ASSIGN(path, aString);
	}
	else if (nil == filename)
	{
		ASSIGN(filename, aString);
	}
	else if (nil == firstLine)
	{
		ASSIGN(firstLine, [NSNumber numberWithInt: [aString intValue]]);
	}
	else if (nil == lastLine)
	{
		NSString *f = [path stringByAppendingPathComponent: filename];
		ASSIGN(lastLine, [NSNumber numberWithInt: [aString intValue]]);
		[[self root] endParagraph];
		[self.builder startNodeWithStyle: 
			[self.document typeFromDictionary: D(
				ETTextForeignImportType, kETTextStyleName,
				f, kETTextSourceLocation,
				firstLine, kETTextFirstLine,
				lastLine, kETTextLastLine,
				refType, @"TRImportType")]];
		[self.builder endNode];
		self.scanner.delegate = self.parent;
	}
}
@end
@implementation TRTeXImportedListing
- (void)beginCommand: (NSString*)aCommand
{
	ASSIGN(refType, aCommand);
}
- (void)dealloc
{
	[refType release];
	[super dealloc];
}
- (void)handleText: (NSString*)aString
{
	[[self root] endParagraph];
	[self.builder startNodeWithStyle: 
		[self.document typeFromDictionary: D(
			ETTextForeignImportType, kETTextStyleName,
			aString, kETTextSourceLocation,
			refType, @"TRImportType")]];
	[self.builder endNode];
	self.scanner.delegate = self.parent;
}
@end

@implementation TRTeXKeywordHandler
- (void)beginCommand: (NSString*)aString {}
- (void)beginOptArg
{
	inOptArg = YES;
}
- (void)endOptArg
{
	inOptArg = NO;
}
- (void)handleText: (NSString*)aString
{
	if (inOptArg)
	{
		ASSIGN(indexText, aString);
		return;
	}
	NSString *idxText = indexText ? indexText : aString;
	ETTextTreeBuilder *builder = self.builder;
	[builder startNodeWithStyle: 
		[self.document typeFromDictionary: D(
			ETTextLinkTargetType, kETTextStyleName,
			idxText, kETTextLinkIndexText,
			[ETUUID UUID], kETTextLinkName)]];
	[builder startNodeWithStyle: 
		[self.document typeFromDictionary: D(
			@"keyword", kETTextStyleName)]];
	[builder appendString: aString];
	[builder endNode];
	[builder endNode];

	[indexText release];
}
- (void)endArgument
{
	self.scanner.delegate = self.parent;
}
@end

@implementation TRTeXKeyabrvHandler
- (void)dealloc
{
	[phrase release];
	[abbreviation release];
	[super dealloc];
}
- (void)beginCommand: (NSString*)aString {}
- (void)handleText: (NSString*)aString
{
	if (nil == phrase)
	{
		ASSIGN(phrase, aString);
	}
	else if (nil == abbreviation)
	{
		ASSIGN(abbreviation, aString);
	}
}
- (void)endArgument
{
	if (nil == abbreviation) { return; }
	ETTextTreeBuilder *builder = self.builder;
	// Emit the keyword-style text
	[builder startNodeWithStyle: 
		[self.document typeFromDictionary: D(
			@"keyword", kETTextStyleName)]];
	[builder appendString: phrase];
	[builder endNode];
	// Emit the dictionary entry
	[builder startNodeWithStyle: 
		[self.document typeFromDictionary: D(
			ETTextLinkTargetType, kETTextStyleName,
			abbreviation, kETTextLinkIndexCrossReference,
			phrase, kETTextLinkIndexText,
			[ETUUID UUID], kETTextLinkName)]];
	[self.builder endNode];
	self.scanner.delegate = self.parent;
}
@end

@implementation TRTeXClassHandler
- (void)beginCommand: (NSString*)aString {}
- (void)handleText: (NSString*)aString
{
	ETTextTreeBuilder *builder = self.builder;
	[builder startNodeWithStyle: 
		[self.document typeFromDictionary: D(
			ETTextLinkTargetType, kETTextStyleName,
			([NSString stringWithFormat: @"%@ class", aString]), kETTextLinkIndexText,
			[ETUUID UUID], kETTextLinkName)]];
	[builder endNode];
	[builder startNodeWithStyle: 
		[self.document typeFromDictionary: D(
			@"code", kETTextStyleName)]];
	[builder appendString: aString];
	[builder endNode];
}
- (void)endArgument
{
	self.scanner.delegate = self.parent;
}
@end
@implementation TRTeXTildeHack
- (void)beginCommand: (NSString*)aString 
{
	[self.builder appendString: @"~"];
}
- (void)endArgument
{
	self.scanner.delegate = self.parent;
}
@end

@interface TRXHTMLImportBuilder : NSObject <ETXHTMLWriterDelegate>
@property (nonatomic, copy) NSString *rootPath;
@property (nonatomic, copy) NSDictionary *includePaths;
@property (nonatomic, copy) NSDictionary *captionFormats;
@end

static SCKSourceCollection *allSources;

@implementation TRXHTMLImportBuilder
@synthesize rootPath, includePaths, captionFormats;
+ (void)initialize
{
	allSources = [SCKSourceCollection new];
}

- (void)dealloc
{
	[rootPath release];
	[includePaths release];
	[captionFormats release];
	[super dealloc];
}
- (void)writer: (ETXHTMLWriter*)aWriter startTextNode: (id<ETText>)aNode;
{
	LOCAL_AUTORELEASE_POOL();
	ETXMLWriter *writer = aWriter.writer;
	// Resolve the absolute path.
	NSString *includeType = [aNode.textType valueForKey: @"TRImportType"];
	NSString *directory = [includePaths objectForKey: includeType];
	if (![directory isAbsolutePath])
	{
		directory = [rootPath stringByAppendingPathComponent: directory];
	}
	NSString *fileName = 
		[directory stringByAppendingPathComponent: 
			[aNode.textType valueForKey: kETTextSourceLocation]];
	NSString *file = [NSString stringWithContentsOfFile: fileName];
	if (nil == file)
	{
		NSString *err = [NSString stringWithFormat: 
			@"Can't find refrenced file: %@ (%@)", 
			fileName, includeType];
		[writer startAndEndElement: @"p"
		                     cdata: err];
		NSLog(@"%@", err);
	}
	else
	{
		//Different class for each snippet type
		NSDictionary *class =
			D([@"include " stringByAppendingString: includeType], 
				@"class");
		[writer startElement: @"pre"
		          attributes: class];
		// Do the syntax highlighting
		NSMutableAttributedString *source = 
			[[NSMutableAttributedString alloc] initWithString: file];
		SCKSourceFile *sourceFile = [allSources sourceFileForPath: fileName];
		sourceFile.source = source;
		[sourceFile addIncludePath: @"."];
		[sourceFile addIncludePath: @"/usr/local/include"];
		[sourceFile addIncludePath: @"/usr/local/GNUstep/Local/Library/Headers"];
		[sourceFile addIncludePath: @"/usr/local/GNUstep/System/Library/Headers"];
		[sourceFile reparse];
		[sourceFile syntaxHighlightFile];

		NSInteger startLine = 
			[[aNode.textType valueForKey: kETTextFirstLine] integerValue];
		NSInteger endLine = 
			[[aNode.textType valueForKey: kETTextLastLine] integerValue];
		if (0 != endLine)
		{
			endLine -= startLine;
			endLine += 1;
		}

		NSInteger start=0;
		NSInteger length = [file length];
		NSInteger end= [file length];

		NSRange searchRange = {start, end};
		// If start is specified, then make it to 0-indexed 
		while (startLine > 1)
		{
			// Find the next line break
			NSRange found = [file rangeOfCharacterFromSet: [NSCharacterSet newlineCharacterSet]
			                                      options: 0
			                                        range: searchRange];
			if (NSNotFound == found.location) { break; }
			start = found.location + found.length;
			searchRange.location = found.location + found.length;
			searchRange.length = length - searchRange.location;
			startLine--;
		}
		while (endLine > 0)
		{
			// Find the next line break
			NSRange found = [file rangeOfCharacterFromSet: [NSCharacterSet newlineCharacterSet]
			                                      options: 0
			                                        range: searchRange];
			if (NSNotFound == found.location) { break; }
			end = found.location + found.length;
			searchRange.location = found.location + found.length;
			searchRange.length = length - searchRange.location;
			endLine--;
		}
		NSUInteger i = start;
		do
		{
			NSRange r;
			NSDictionary *attrs = [source attributesAtIndex: i
			                          longestEffectiveRange: &r
			                                        inRange: NSMakeRange(i, end-i)];
			i = r.location + r.length;
			NSString *token = [attrs objectForKey: kSCKTextTokenType];
			NSString *semantic = [attrs objectForKey: kSCKTextSemanticType];
			NSDictionary *attributes = nil;
			// Skip ranges that have attributes other than semantic markup
			if (semantic == SCKTextTypePreprocessorDirective)
			{
				attributes = D(semantic, @"class");
			}
			else if (token != SCKTextTokenTypeIdentifier)
			{
				attributes = D(token, @"class");
			}
			else 
			{
				attributes = D(semantic, @"class");
			}
			[writer startAndEndElement: @"span"
			                attributes: attributes
			                     cdata: [file substringWithRange: r]];
		} while (i < end);
		[writer endElement: @"pre"];
	}
	[writer startElement: @"p"
			  attributes: D(@"caption", @"class")];
	NSString *caption = [captionFormats objectForKey: includeType];
	caption = [NSString stringWithFormat: caption, 
		[[aNode.textType valueForKey: kETTextSourceLocation] 
			lastPathComponent]];
	[writer characters: caption];
}

- (void)writer: (ETXHTMLWriter*)writer visitTextNode: (id<ETText>)aNode {}
- (void)writer: (ETXHTMLWriter*)writer endTextNode: (id<ETText>)aNode {}
@end


int main(int argc, char **argv)
{
	[NSAutoreleasePool new];
	NSCAssert(argc > 1, @"Path must be specified as an argument");

	NSString *projectRoot = [NSString stringWithUTF8String: argv[1]];
	NSString *projectDescription = [projectRoot stringByAppendingPathComponent: @"html.plist"];
	NSDictionary *project = [NSDictionary dictionaryWithContentsOfFile: projectDescription];
	ETTeXParser *d2 = [ETTeXParser new];
	NSDictionary *handlers = [project objectForKey: @"customHandlers"];
	for (NSString *command in handlers)
	{
		[d2 registerDelegate: NSClassFromString([handlers objectForKey: command])
		          forCommand: command];
	}
	NSDictionary *types = [project objectForKey: @"typeNames"];
	for (NSString *command in types)
	{
		[ETTeXSimpleHandler setTextType: [types objectForKey: command]
						  forTeXCommand: command];
	}
	// Uncomment to tidy up hand-edited plist
	//[project writeToFile: projectDescription atomically: NO];
	ETTeXScanner *s = [ETTeXScanner new];
	d2.scanner = s;
	s.delegate = d2;
	[ETTeXEnvironmentHandler addVerbatimEnvironment: @"shortlisting"];

	for (NSString *path in [project objectForKey: @"chapters"])
	{
		NSString * tex = [projectRoot stringByAppendingPathComponent: path];
		tex = [NSString stringWithContentsOfFile: tex];
		[s parseString: tex];
	}
	//NSLog(@"Parsed TeX: \n%@", d2.document.text);
	ETXHTMLWriter *w = [ETXHTMLWriter new];
	w.writeChaptersToFiles = YES;
	TRXHTMLImportBuilder *importer = [TRXHTMLImportBuilder new];
	importer.rootPath = projectRoot;
	importer.includePaths = [project objectForKey: @"includeDirectories"];
	importer.captionFormats = [project objectForKey: @"captionFormats"];
	[w setDelegate: importer forTextType: ETTextForeignImportType];
	[w setDelegate: [ETXHTMLAutolinkingHeadingBuilder new] forTextType: ETTextHeadingType];
	[importer release];

	types = [project objectForKey: @"htmlTags"];
	for (NSString *type in types)
	{
		[w setTagName: [types objectForKey: type]
		  forTextType: type];
	}
	types = [project objectForKey: @"htmlAttributes"];
	for (NSString *type in types)
	{
		[w setAttributes: [types objectForKey: type]
		     forTextType: type];
	}
	[w generateHTMLForDocument: d2.document.text];
	/*
	NSString *html = [w endDocument];
	//NSLog(@"Parsed TeX: \n%@", html);
	[html writeToFile: @"tex.html" atomically: NO];
	*/
	/*
	[d2 retain];
	[NSApplication sharedApplication];
	[d2.document.text inspector];
	[[NSRunLoop currentRunLoop] run];
	*/
	return 0;
}
