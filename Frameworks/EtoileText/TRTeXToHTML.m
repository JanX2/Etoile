#import "EtoileText.h"
#import <EtoileFoundation/EtoileFoundation.h>
#import "ETTeXHandlers.h"
@interface TRTeXImportNumberedListing : ETTeXHandler
{
	NSString *refType;
	NSString *filename;
	NSNumber *firstLine;
	NSNumber *lastLine;
}
@end
@interface TRTeXSystemSnippet : TRTeXImportNumberedListing
{
	NSString *path;
}
@end
@interface TRTeXImportedListing : ETTeXHandler
{
	NSString *refType;
}
@end


@interface TRTeXKeywordHandler : ETTeXHandler
{
	NSString *indexText;
	BOOL inOptArg;
}
@end
@interface TRTeXKeyabrvHandler : ETTeXHandler 
{
	NSString *phrase;
	NSString *abbreviation;
}
@end

@interface TRTeXClassHandler : ETTeXHandler @end
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
			@"keyword", kETTextStyleName)]];
	[builder startNodeWithStyle: 
		[self.document typeFromDictionary: D(
			ETTextLinkTargetType, kETTextStyleName,
			idxText, kETTextLinkIndexText,
			[ETUUID UUID], kETTextLinkName)]];
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
	NSString *indexEntry = 
		[NSString stringWithFormat: @"%@|see{%@}", phrase, abbreviation];
	[builder startNodeWithStyle: 
		[self.document typeFromDictionary: D(
			ETTextLinkTargetType, kETTextStyleName,
			indexEntry, kETTextLinkIndexText,
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

@class ETXHTMLWriter;
@protocol ETXHTMLWriterDelegate
- (void)writer: (ETXHTMLWriter*)aWriter startTextNode: (id<ETText>)aNode;
- (void)writer: (ETXHTMLWriter*)aWriter visitTextNode: (id<ETText>)aNode;
- (void)writer: (ETXHTMLWriter*)aWriter endTextNode: (id<ETText>)aNode;
@end

@interface ETXHTMLWriter : NSObject <ETTextVisitor>
{
	NSMutableDictionary *types;
	NSMutableDictionary *defaultAttributes;
	NSMutableDictionary *customHandlers;
	BOOL isWritingFootnotes;
}
@property (nonatomic, retain) ETXMLWriter *writer;
@property (nonatomic, copy) NSString *rootPath;
@property (nonatomic, copy) NSDictionary *includePaths;
@property (nonatomic, copy) NSDictionary *captionFormats;
@property (nonatomic, assign) id skipToEndOfNode;
- (void)setTagName: (NSString*)aString forTextType: (NSString*)aType;
- (void)setAttributes: (NSDictionary*)attributes forTextType: (NSString*)aType;
- (void)setDelegate: (id<ETXHTMLWriterDelegate>)aDelegate forTextType: (NSString*)aType;
- (NSString*)endDocument;
@end

@interface ETXHTMLFootnoteBuilder : NSObject <ETXHTMLWriterDelegate>
{
	NSMutableArray *footnotes;
}
@end
@implementation ETXHTMLFootnoteBuilder
- (id)init
{
	SUPERINIT;
	footnotes = [NSMutableArray new];
	return self;
}
- (void)dealloc
{
	[footnotes release];
	[super dealloc];
}
- (void)writer: (ETXHTMLWriter*)aWriter startTextNode: (id<ETText>)aNode;
{
	// Record this footnote for writing later
	[footnotes addObject: aNode];
	// Don't output the body of the footnote here.
	aWriter.skipToEndOfNode = aNode;
	// Emit a numbered link to the footnote now.
	NSInteger footnoteNumber = [footnotes count];
	NSString *linkText = 
		[NSString stringWithFormat: @"%d", footnoteNumber];
	NSString *footnoteLabel = 
		[NSString stringWithFormat: @"#footnote%d", footnoteNumber];

	ETXMLWriter *writer = aWriter.writer;
	[writer startElement: @"sup"];
	[writer startAndEndElement: @"a"
	                attributes: D(footnoteLabel, @"href")
	                     cdata: linkText];
	[writer endElement];
}
- (void)writer: (ETXHTMLWriter*)writer visitTextNode: (id<ETText>)aNode {}
- (void)writer: (ETXHTMLWriter*)writer endTextNode: (id<ETText>)aNode {}
- (void)writeCollectedFootnotesForXHTMLWriter: (ETXHTMLWriter*)aWriter
{
	// Remove self as the handler for footnotes, so that they are passed
	// through as-is
	[aWriter setDelegate: nil forTextType: @"footnote"];
	ETXMLWriter *writer = aWriter.writer;
	NSInteger footnoteNumber = 1;
	for (id<ETText> footnote in footnotes)
	{
		NSString *linkText = 
			[NSString stringWithFormat: @"%d", footnoteNumber];
		NSString *footnoteLabel = 
			[NSString stringWithFormat: @"footnote%d", footnoteNumber];
		[writer startElement: @"p"
		          attributes: D(@"footnote", @"class")];
		[writer startElement: @"sup"];
		[writer startAndEndElement: @"a"
		                attributes: D(footnoteLabel, @"name")
		                     cdata: @" "];
		[writer characters: linkText];
		[writer endElement];
		[writer characters: @" "];
		[footnote visitWithVisitor: aWriter];
		[writer endElement];
		footnoteNumber++;
	}
	[footnotes removeAllObjects];
	[aWriter setDelegate: self forTextType: @"footnote"];
}
@end

@implementation ETXHTMLWriter
@synthesize writer, rootPath, includePaths, captionFormats, skipToEndOfNode;
- (id)init
{
	SUPERINIT;
	writer = [ETXMLWriter new];
	//[writer setAutoindent: YES];
	[writer startElement: @"html"]; 
	[writer startElement: @"head"]; 
	{
		[writer startAndEndElement: @"link"
		                attributes: D(@"stylesheet", @"rel",
		                              @"text/css", @"type",
		                              @"tex.css", @"href")];
	}
	[writer endElement];
	[writer startElement: @"body"]; 
	types = [D(@"ul", ETTextListType,
		@"ol", ETTextNumberedListType,
		@"dl", ETTextDescriptionListType,
		@"dt", ETTextListDescriptionTitleType,
		@"dd", ETTextListDescriptionItemType,
		@"li", ETTextListItemType) mutableCopy];
	defaultAttributes = [NSMutableDictionary new];
	customHandlers = [NSMutableDictionary new];
	return self;
}
- (void)dealloc
{
	[defaultAttributes release];
	[types release];
	[customHandlers release];
	[writer release];
	[rootPath release];
	[includePaths release];
	[captionFormats release];
	[super dealloc];
}
- (void)setTagName: (NSString*)aString forTextType: (NSString*)aType
{
	[types setObject: aString forKey: aType];
}
- (void)setAttributes: (NSDictionary*)attributes forTextType: (NSString*)aType
{
	[defaultAttributes setObject: attributes forKey: aType];
}
- (void)setDelegate: (id<ETXHTMLWriterDelegate>)aDelegate forTextType: (NSString*)aType
{
	[customHandlers setObject: aDelegate forKey: aType];
}
- (void)startTextNode: (id<ETText>)aNode
{
	if (nil != skipToEndOfNode) { return; }

	NSString *typeName = [aNode.textType valueForKey: kETTextStyleName];
	id<ETXHTMLWriterDelegate> delegate = [customHandlers objectForKey: typeName];
	if (nil != delegate)
	{
		[delegate writer: self startTextNode: aNode];
		return;
	}
	if (nil != typeName)
	{
		//TODO: Handle standard attributes here, call a delegate for others.
		// FIXME: This blob of nested if statements is horrible.  Split each
		// body into a separate method.
		NSDictionary *attributes = nil;
		if ([ETTextParagraphType isEqualToString: typeName])
		{
			typeName = @"p";
			if ([aNode length] == 0) { return; }
		}
		else if ([ETTextHeadingType isEqualToString: typeName])
		{
			typeName = [NSString stringWithFormat: @"h%@",
					[aNode.textType valueForKey: kETTextHeadingLevel]];
		}
		else if (!isWritingFootnotes &&
			[@"footnote" isEqualToString: typeName])
		{
		}
		else if ([ETTextLinkTargetType isEqualToString: typeName])
		{
			NSString *linkName = [aNode.textType valueForKey: kETTextLinkName];
			typeName = @"a";
			attributes = D([linkName stringValue], @"name");
		}
		else if ([ETTextForeignImportType isEqualToString: typeName])
		{
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
				NSArray *lines = [file componentsSeparatedByString: @"\n"];
				NSInteger start = 
					[[aNode.textType valueForKey: kETTextFirstLine] integerValue];
				NSInteger end = 
					[[aNode.textType valueForKey: kETTextLastLine] integerValue];
				// If start is specified, then make it to 0-indexed 
				if (start > 0) { start -= 1; }
				if (end == 0) { end = [lines count] - 1; }
				for (NSInteger i=start ; i<end ; i++)
				{
					NSString *line = [lines objectAtIndex: i];
					[writer characters: line];
					[writer characters: @"\n"];
				}
				[writer endElement: @"pre"];
			}
			[writer startElement: @"p"
					  attributes: D(@"caption", @"class")];
			NSString *caption = [captionFormats objectForKey: includeType];
			caption = [NSString stringWithFormat: caption, 
				[[aNode.textType valueForKey: kETTextSourceLocation] 
					lastPathComponent]];
			[writer characters: caption];
			return;
		}
		else
		{
			attributes = [defaultAttributes objectForKey: typeName];
			attributes = attributes ? attributes : D(typeName, @"class");
			NSString *defaultType = [types objectForKey: typeName];
			typeName = defaultType ? typeName : @"span";
		}
		[writer startElement: typeName
				  attributes: attributes];
	}
}
- (void)visitTextNode: (id<ETText>)aNode
{
	if (nil != skipToEndOfNode) { return; }

	NSString *typeName = [aNode.textType valueForKey: kETTextStyleName];

	id<ETXHTMLWriterDelegate> delegate = [customHandlers objectForKey: typeName];
	if (nil != delegate)
	{
		[delegate writer: self visitTextNode: aNode];
		return;
	}

	NSString *str = [[aNode stringValue] stringByTrimmingCharactersInSet:
		[NSCharacterSet newlineCharacterSet]];
	if ([str length] > 0)
	{
		[writer characters: str];
	}
	else if ([ETTextLinkTargetType isEqualToString: typeName])
	{
		[writer characters: @" "];
	}
}
- (void)endTextNode: (id<ETText>)aNode
{
	if (nil != skipToEndOfNode) 
	{ 
		if (skipToEndOfNode == aNode)
		{
			skipToEndOfNode = nil;
		}
		return; 
	}

	NSString *typeName = [aNode.textType valueForKey: kETTextStyleName];
	id<ETXHTMLWriterDelegate> delegate = [customHandlers objectForKey: typeName];
	if (nil != delegate)
	{
		[delegate writer: self endTextNode: aNode];
		return;
	}

	if (nil != [aNode.textType valueForKey: kETTextStyleName])
	{
		NSString *typeName = [aNode.textType valueForKey: kETTextStyleName];
		if ([ETTextParagraphType isEqualToString: typeName])
		{
			if ([aNode length] == 0) { return; }
		}
		[writer endElement];
	}
}
- (NSString*)endDocument
{
	[writer endElement];
	[writer endElement];
	return [writer endDocument];
}
@end
@interface NSMutableDictionary (DictionaryOfLists)
- (void)addObject: anObject forKey: aKey;
@end
@implementation NSMutableDictionary (DictionaryOfLists)
- (void)addObject: anObject forKey: aKey
{
	id old = [self objectForKey: aKey];
	if (nil == old)
	{
		[self setObject: anObject forKey: aKey];
	}
	else
	{
		if ([old isKindOfClass: [NSMutableArray class]])
		{
			[(NSMutableArray*)old addObject: anObject];
		}
		else
		{
			[self setObject: [NSMutableArray arrayWithObjects: old, anObject, nil]
			         forKey: aKey];
		}
	}
}
@end

@interface ETReferenceBuilder : NSObject <ETTextVisitor>
{
	/** Text nodes referring to other elements. */
	NSMutableArray *referenceNodes;
	/** Link targets. */
	NSMutableDictionary *linkTargets;
	NSMutableDictionary *linkNames;
	/** Index entries. */
	NSMutableDictionary *indexEntries;
	int sectionCounter[10];
	int sectionCounterDepth;
}
- (void)finishVisiting;
@property (readonly) NSArray *referenceNodes;
@property (readonly) NSDictionary *linkTargets;
@property (readonly) NSDictionary *linkNames;
@end
@implementation ETReferenceBuilder
@synthesize referenceNodes, linkTargets, linkNames;
- init
{
	SUPERINIT;
	referenceNodes = [NSMutableArray new];
	linkTargets = [NSMutableDictionary new];
	linkNames = [NSMutableDictionary new];
	indexEntries = [NSMutableDictionary new];
	return self;
}
- (void)dealloc
{
	[referenceNodes release];
	[linkTargets release];
	[linkNames release];
	[indexEntries release];
	[super dealloc];
}
- (void)startTextNode: (id<ETText>)aNode 
{
	id type = aNode.textType;
	if ([ETTextHeadingType isEqualToString: [type valueForKey: kETTextStyleName]])
	{
		int level = [[type valueForKey: kETTextHeadingLevel] intValue];
		NSAssert(level < 10, @"Indexer can only handle 10 levels of headings.");
		sectionCounter[level]++;
		sectionCounterDepth = level;
		// Don't renumber chapters when we start a new part
		if (level == 0) { level = 1; }
		sectionCounter[level+1] = 0;
	}
}
- (void)visitTextNode: (id<ETText>)aNode
{
	id type = aNode.textType;
	NSString *typeName = [typeName valueForKey: kETTextStyleName];
	if ([ETTextLinkType isEqualToString: typeName])
	{
		[referenceNodes addObject: aNode];
	}
	else if ([ETTextLinkTargetType isEqualToString: typeName])
	{
		NSString *linkName = [type valueForKey: kETTextLinkName];
		NSMutableString *sectionNumber = 
			[NSMutableString stringWithFormat: @"%d", sectionCounter[1]];
		for (int i=2 ; i<=sectionCounterDepth ; i++)
		{
			[sectionNumber appendFormat: @".%d", sectionCounter[i]];
		}
		[linkNames setObject: sectionNumber
		              forKey: linkName];
		[linkTargets setObject: aNode
		                forKey: linkName];
		NSString *indexName = [type valueForKey: kETTextLinkIndexText];
		if (nil != indexName)
		{
			[indexEntries addObject: linkName
			                 forKey: indexName];
		}
	}
}
- (void)endTextNode: (id<ETText>)aNode {}
- (void)finishVisiting
{
	for (id<ETText> link in referenceNodes)
	{
		NSUInteger length = [link length];
		NSString *target = 
			[linkNames objectForKey: [link.textType valueForKey: kETTextLinkName]];
		if (nil == target) { target = @"??"; }
		[link replaceCharactersInRange: NSMakeRange(0, length)
		                    withString: target];
	}
}
// FIXME: This should be part of the XML writer, not part of the ref builder
- (void)writeIndexWithXMLWriter: (ETXMLWriter*)writer
{
	[writer startAndEndElement: @"h1"
	                     cdata: @"Index"];
	[writer startElement: @"div"
	          attributes: D(@"index", @"class")];
	NSArray *entries = [[indexEntries allKeys] 
		sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
	unichar startChar = 0;
	BOOL inIndexList = NO;
	for (NSString *entry in entries)
	{
		if (tolower([entry characterAtIndex: 0]) != startChar)
		{
			startChar = tolower([entry characterAtIndex: 0]);
			if (inIndexList)
			{
				[writer endElement];
			}
			inIndexList = YES;
			[writer startAndEndElement: @"h2"
			                attributes: D(@"index", @"class")
			                     cdata: [NSString stringWithFormat: @"%c", toupper(startChar)]];
			[writer startElement: @"p"];
		}
		id targets = [indexEntries objectForKey: entry];
		if ([targets isKindOfClass: [NSArray class]])
		{
			[writer characters: entry];
			[writer characters: @", "];
			for (id t in targets)
			{
				NSString *ref = [NSString stringWithFormat: @"#%@", t];
				NSString *section = [linkNames objectForKey: t];
				[writer startAndEndElement: @"a"
				                attributes: D(ref, @"href")
				                     cdata: section];
				[writer characters: @" "];
			}
		}
		else
		{
			[writer startAndEndElement: @"a"
			                attributes: D([NSString stringWithFormat: @"#%@", targets], @"href")
			                     cdata: entry];
		}
		[writer startAndEndElement: @"br"];
	}
	if (inIndexList)
	{
		[writer endElement];
	}
	[writer endElement];
}
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

	for (NSString *path in [project objectForKey: @"chapters"])
	{
		NSString * tex = [projectRoot stringByAppendingPathComponent: path];
		tex = [NSString stringWithContentsOfFile: tex];
		[s parseString: tex];
	}
	//NSLog(@"Parsed TeX: \n%@", d2.document.text);
	ETReferenceBuilder *r = [ETReferenceBuilder new];
	[d2.document.text visitWithVisitor: r];
	[r finishVisiting];
	ETXHTMLWriter *w = [ETXHTMLWriter new];
	ETXHTMLFootnoteBuilder *footnotes = [ETXHTMLFootnoteBuilder new];
	[w setDelegate: footnotes forTextType: @"footnote"];

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
	w.rootPath = projectRoot;
	w.includePaths = [project objectForKey: @"includeDirectories"];
	w.captionFormats = [project objectForKey: @"captionFormats"];
	[d2.document.text visitWithVisitor: w];
	[footnotes writeCollectedFootnotesForXHTMLWriter: w];
	[r writeIndexWithXMLWriter: w.writer];
	NSString *html = [w endDocument];
	//NSLog(@"Parsed TeX: \n%@", html);
	[html writeToFile: @"tex.html" atomically: NO];
}
