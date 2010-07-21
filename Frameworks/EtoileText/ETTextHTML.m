#import "EtoileText.h"

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
	[writer startElement: @"a"
	         attributes: D(footnoteLabel, @"href")];
	[writer startAndEndElement: @"sup"
	                     cdata: linkText];
	[writer endElement];
}
- (void)writer: (ETXHTMLWriter*)writer visitTextNode: (id<ETText>)aNode {}
- (void)writer: (ETXHTMLWriter*)writer endTextNode: (id<ETText>)aNode {}
- (void)writeCollectedFootnotesForXHTMLWriter: (ETXHTMLWriter*)aWriter
{
	// If the builder has the only reference to this object, we don't want it
	// to be deleted while in use!
	[self retain];
	// Remove self as the handler for footnotes, so that they are passed
	// through as-is
	[aWriter setDelegate: nil forTextType: ETTextFootnoteType];
	ETXMLWriter *writer = aWriter.writer;
	NSInteger footnoteNumber = 1;
	for (id<ETText> footnote in footnotes)
	{
		NSString *linkText = 
			[NSString stringWithFormat: @"%d", footnoteNumber];
		NSString *footnoteLabel = 
			[NSString stringWithFormat: @"footnote%d", footnoteNumber];
		[writer startElement: @"p"
		          attributes: D(ETTextFootnoteType, @"class")];
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
	[aWriter setDelegate: self forTextType: ETTextFootnoteType];
	[self release];
}
@end

@implementation ETXHTMLHeadingBuilder
- (void)writer: (ETXHTMLWriter*)aWriter startTextNode: (id<ETText>)aNode;
{
	[aWriter.writer startElement: [NSString stringWithFormat: @"h%@",
			[aNode.textType valueForKey: kETTextHeadingLevel]]];
}
- (void)writer: (ETXHTMLWriter*)aWriter visitTextNode: (id<ETText>)aNode
{
	NSString *str = [[aNode stringValue] stringByTrimmingCharactersInSet:
		[NSCharacterSet newlineCharacterSet]];
	[aWriter.writer characters: str];
}
- (void)writer: (ETXHTMLWriter*)aWriter endTextNode: (id<ETText>)aNode
{
	[aWriter.writer endElement];
}
@end

@implementation ETXHTMLAutolinkingHeadingBuilder
- (void)writer: (ETXHTMLWriter*)aWriter startTextNode: (id<ETText>)aNode;
{
	[aWriter.writer startElement: @"a"
					  attributes: D(
	  [NSString stringWithFormat: @"heading_%d", headingNumber++], @"name")];
	[super writer: aWriter startTextNode: aNode];
}
- (void)writer: (ETXHTMLWriter*)aWriter endTextNode: (id<ETText>)aNode
{
	[super writer: aWriter endTextNode: aNode];
	[aWriter.writer endElement];
}
@end

@implementation ETXHTMLWriter
@synthesize writer, skipToEndOfNode;
- (id)init
{
	SUPERINIT;
	writer = [ETXMLWriter new];
	[writer writeXMLHeader];
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
	STACK_SCOPED ETXHTMLHeadingBuilder *headings = [ETXHTMLHeadingBuilder new];
	customHandlers = [D(headings, ETTextHeadingType) mutableCopy];
	return self;
}
- (void)dealloc
{
	[defaultAttributes release];
	[types release];
	[customHandlers release];
	[writer release];
	[super dealloc];
}
- (void)setTagName: (NSString*)aString forTextType: (NSString*)aType
{
	[types setValue: aString forKey: aType];
}
- (void)setAttributes: (NSDictionary*)attributes forTextType: (NSString*)aType
{
	[defaultAttributes setValue: attributes forKey: aType];
}
- (void)setDelegate: (id<ETXHTMLWriterDelegate>)aDelegate forTextType: (NSString*)aType
{
	[customHandlers setValue: aDelegate forKey: aType];
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
		NSDictionary *attributes = nil;
		if ([ETTextParagraphType isEqualToString: typeName])
		{
			typeName = @"p";
			if ([aNode length] == 0) { return; }
		}
		else if ([ETTextLinkTargetType isEqualToString: typeName])
		{
			NSString *linkName = [aNode.textType valueForKey: kETTextLinkName];
			typeName = @"a";
			attributes = D([linkName stringValue], @"name");
		}
		else
		{
			attributes = [defaultAttributes objectForKey: typeName];
			attributes = attributes ? attributes : D(typeName, @"class");
			NSString *defaultType = [types objectForKey: typeName];
			typeName = defaultType ? defaultType : @"span";
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
	[writer characters: str];
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

@implementation ETReferenceBuilder
@synthesize referenceNodes, linkTargets, linkNames, crossReferences, headings;
- init
{
	SUPERINIT;
	referenceNodes = [NSMutableArray new];
	headings = [NSMutableArray new];
	linkTargets = [NSMutableDictionary new];
	linkNames = [NSMutableDictionary new];
	crossReferences = [NSMutableDictionary new];
	indexEntries = [NSMutableDictionary new];
	return self;
}
- (void)dealloc
{
	[referenceNodes release];
	[linkTargets release];
	[headings release];
	[linkNames release];
	[indexEntries release];
	[crossReferences release];
	[super dealloc];
}
- (void)startTextNode: (id<ETText>)aNode 
{
	id type = aNode.textType;
	if ([ETTextHeadingType isEqualToString: [type valueForKey: kETTextStyleName]])
	{
		[headings addObject: aNode];
		if (![type valueForKey: kETTextLinkName])
		{
		
		}
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
			NSString *xref = [type valueForKey: kETTextLinkIndexCrossReference];
			if (nil != xref)
			{
				[crossReferences addObject: indexName
				                    forKey: xref];
			}
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
// FIXME: This is quite ugly.  It would probably be cleaner to make headings
// into links automatically in the text tree.
- (void)writeTableOfContentsWithXMLWriter: (ETXMLWriter*)writer
{
	int headingNumber = 0;
	int headingDepth = 0;
	[writer startAndEndElement: @"h1"
	                     cdata: @"Table of Contents"];
	for (id<ETText> heading in headings)
	{
		int headingLevel = [[heading.textType valueForKey: kETTextHeadingLevel] intValue];
		while (headingLevel > headingDepth)
		{
			[writer startElement: @"ol"
					  attributes: D([NSString stringWithFormat: @"toc%d", headingDepth], @"class")];
			headingDepth++;
		}
		while (headingLevel < headingDepth)
		{
			[writer endElement];
			headingDepth--;
		}
		[writer startElement: @"li"];
		[writer startAndEndElement: @"a"
		                attributes: D([NSString stringWithFormat: @"#heading_%d", headingNumber++], @"href")
		                     cdata: [heading stringValue]];
		[writer endElement];
	}
	while (0 < headingDepth)
	{
		[writer endElement];
		headingDepth--;
	}
}
// FIXME: This should be part of the XML writer, not part of the ref builder
// FIXME: Ideally, we'd construct the ETText tree for the index, and then emit
// it using whatever generator we chose.
- (void)writeIndexWithXMLWriter: (ETXMLWriter*)writer
{
	[writer startAndEndElement: @"h1"
	                     cdata: @"Index"];
	[writer startElement: @"div"
	          attributes: D(@"index", @"class")];
	NSArray *entries = 
		[[[indexEntries allKeys] 
			arrayByAddingObjectsFromArray: [crossReferences allKeys]]
				sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
	unichar startChar = 0;
	BOOL inIndexList = NO;
	NSString *lastEntry = nil;
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
		NSArray *split = [entry componentsSeparatedByString: @"!"];
		NSString *displayEntry = entry;
		if ([split count] > 1)
		{
			NSString *parent = [split objectAtIndex: 0];
			if (![parent isEqualToString: lastEntry])
			{
				[writer characters: parent];
			}
			displayEntry = [split objectAtIndex: 1];
			[writer startElement: @"p"
			          attributes: D(@"index subentry", @"class")];
		}
		else
		{
			lastEntry = entry;
			[writer startElement: @"p"
			          attributes: D(@"index", @"class")];
		}
		id targets = [indexEntries objectForKey: entry];
		if (nil != targets)
		{
			if ([targets isKindOfClass: [NSArray class]])
			{
				[writer characters: displayEntry];
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
				                     cdata: displayEntry];
			}
		}
		else
		{
			NSString *xref = [crossReferences objectForKey: entry];
			[writer characters: entry];
			[writer characters: @", see "];
			[writer characters: xref];
		}
		[writer endElement];
	}
	if (inIndexList)
	{
		[writer endElement];
	}
	[writer endElement];
}
@end

