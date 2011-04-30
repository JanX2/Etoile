/*
	Copyright (C) 2008 Nicolas Roard

	Author:  Nicolas Roard
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2008
	License:  Modified BSD (see COPYING)
 */

#import "DocDescriptionParser.h"


@implementation DocDescriptionParser

- (id) init
{
  self = [super init];
  parsed = [NSMutableDictionary new];
  return self;
}

- (void) dealloc
{
  [parsed release];
  [currentTag release];
  [super dealloc];
}

- (id) getContent: (Class) aClass for: (NSString*) tag
{
  if ([parsed objectForKey: tag] == nil)
  {
    id tmp = [aClass new];
    [parsed setObject: tmp forKey: tag];
    [tmp release];
  }
  return [parsed objectForKey: tag];
}

- (NSMutableString*) getStringFor: (NSString*) tag
{
  return (NSMutableString*) [self getContent: [NSMutableString class] for: tag];
}

- (NSMutableDictionary*) getDictionaryFor: (NSString*) tag
{
  return (NSMutableDictionary*) [self getContent: [NSMutableDictionary class] for: tag];
}

- (NSMutableArray *) linesForString: (NSString *)aString
{
	NSUInteger length = [aString length];
	NSRange searchRange = NSMakeRange(0, 0);
	NSMutableArray *lines = [NSMutableArray array];

	while (searchRange.location < length)
	{
		NSUInteger startIndex = 0;
		NSUInteger nextLineIndex = 0;
		NSUInteger separatorIndex = 0;
		NSRange lineRange = NSMakeRange(0, 0);

		[aString getLineStart: &startIndex end: &nextLineIndex contentsEnd: &separatorIndex forRange: searchRange];
		lineRange.location = startIndex;
		lineRange.length = separatorIndex - startIndex;

		[lines addObject: [aString substringWithRange: lineRange]];
		//NSLog(@"Found line: %@|", [lines lastObject]);

		searchRange.location = nextLineIndex;
	}

	return lines;
}

/* Returns the description extracted from 

@tag + [ spaces + description + [ </p> ] + spaces ]

and where sequences enclosed in square brackets are optional.

Requires the line argument to be trimmed, no white spaces at the beginning and end. */ 
- (NSString *) descriptionFromString: (NSString *)aString 
                        isTerminated: (BOOL *)isDescFinished 
                       lineRemainder: (NSString **)unparsedString
{
	NSRange r = [aString rangeOfCharacterFromSet: [NSCharacterSet whitespaceCharacterSet]];
	/* When @tag is alone, we return an empty description, the remaining 
	   description is expected to be parsed in -parseContentLine:forTag: */
	NSString *desc = @"";

	/* Skip the first word and space e.g. @task + space */
	if (r.location != NSNotFound)
	{
		desc = [aString substringFromIndex: r.location + r.length];
	}

	/* Detect multiple tags on the same line, and return the next tag and its 
	   content on the current line through unparsedString */
	NSInteger nextTagIndex = [desc rangeOfString: @"@"].location;
	BOOL hasInlinedTag = (r.location != NSNotFound && nextTagIndex != NSNotFound);

	if (hasInlinedTag)
	{
		*unparsedString = [desc substringFromIndex: nextTagIndex];
		desc = [desc substringToIndex: nextTagIndex];
	}
	else if ([desc hasSuffix: @"</p>"])
	{
		desc = [desc substringToIndex: [desc length] - 4];
		*isDescFinished = YES;
	}
	return [desc trimmedString];
}

- (void) parseParamRawDescription: (NSString *)rawDesc
{
	NSArray *words = [rawDesc componentsSeparatedByString: @" "];
	NSString *paramName = [words firstObject];
	NSArray *descWords = [words subarrayWithRange: NSMakeRange(1, [words count] - 1)];

	[[self getDictionaryFor: @"params"] setObject: [descWords componentsJoinedByString: @" "]
	                                       forKey: paramName];
}

-  (void) parseAnyParamRawDescription
{
	if ([parsed objectForKey: @"@param"] == nil)
		return;

	[self parseParamRawDescription: [parsed objectForKey: @"@param"]];
	[parsed removeObjectForKey: @"@param"];
}

// TODO: Could be improved to keep the markup where it doesn't get in the way. 
// e.g. in each parameter or return description.
- (NSString *) removeBasicDocMarkupForString: (NSString *)desc
{
	if ([desc rangeOfString: @"<"].location == NSNotFound)
		return desc;

 	NSArray *gsdocTagRemovals = A(@"<var>", @"</var>", @"<code>", @"</code>"); 

	for (NSString *tag in gsdocTagRemovals)
	{
		desc = [desc stringByReplacingOccurrencesOfString: tag 
		                                       withString: @""
		                                          options: NSCaseInsensitiveSearch
		                                            range: NSMakeRange(0, [desc length])];
	}

	return desc;
}

- (void) endTag: (NSString *)aTag
{
	ASSIGN(currentTag, nil);
	/* We delay the @param description parsing, because it might be split on 
	   several lines. The parsing might be impossible right when @param is 
	   parsed, because the content to be parsed is on the next line... e.g.
	   @bla A city in the sea. @param
	   myArgument Whatever about this argument. */
	[self parseAnyParamRawDescription];
}

- (void) startTag: (NSString *)aTag
{
	/* When a tag is a limited to a single line, we close it now e.g. 
	   @bla A bird in the sky.
	   @bli A truck on the road. */
	if (currentTag != nil)
	{
		[self endTag: currentTag];
	}
	ASSIGN(currentTag, aTag);
}

/* Returns YES when a new tag has been parsed, whether or not the tag content 
has been entirely parsed. 

Requires the line argument to be trimmed, no white spaces at the beginning and end.

When multiple tags are on the same line, will parse up to the next tag e.g. 
@return, and put the line remainder into unparsedString.<br />
When a single tag is present on the line, unparsedString won't be touched.  */
- (BOOL) parseTag: (NSString *)aTag  atLine: (NSString *)line lineRemainder: (NSString **)unparsedString
{
	NSString *tagWithP = [NSString stringWithFormat: @"<p>%@", aTag];

	if ([line hasPrefix: tagWithP] || [line hasPrefix: aTag])
	{
		[self startTag: aTag];

		BOOL isDescFinished = NO;
		NSString *desc = [self descriptionFromString: line 
		                                isTerminated: &isDescFinished 
		                               lineRemainder: unparsedString];

		desc = [self removeBasicDocMarkupForString: desc];
		[[self getStringFor: aTag] appendString: desc];

		/* If </p> was inserted by autogsdoc as below, we have to close the tag. 
		   @bla Somewhere in the city.</p>
		   <p>main description</p> */
		if (isDescFinished)
		{
			[self endTag: aTag];
		}
		return YES;
	}

	return NO;
}

- (BOOL) isParagraphStartTag: (NSString *)line
{
	NSCharacterSet *blankCharset = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	NSString *trimmedLine = [line stringByTrimmingCharactersInSet: blankCharset];
	return ([trimmedLine isEqualToString: @"<p>"]);
}

- (BOOL) isParagraphStartOrEnd: (NSString *)line
{
	NSCharacterSet *blankCharset = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	NSString *trimmedLine = [line stringByTrimmingCharactersInSet: blankCharset];
	return ([trimmedLine isEqualToString: @""] || [trimmedLine hasSuffix: @"</p>"] || [trimmedLine hasSuffix: @"<p>"]);
}

- (BOOL) parseStartAmongTags: (NSArray *)tags 
                      atLine: (NSString *)line 
              isNewParagraph: (BOOL)isNewParagraph
               lineRemainder: (NSString **)unparsedString
{
	BOOL canParseTag = (isNewParagraph || currentTag != nil);

	if (canParseTag == NO)
		return NO;

	NSCharacterSet *blankCharset = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	NSString *trimmedLine = [line stringByTrimmingCharactersInSet: blankCharset];

	for (NSString *tag in tags)
	{
		BOOL parsedNewTag = [self parseTag: tag atLine: trimmedLine lineRemainder: unparsedString];

		if (parsedNewTag)
			return YES;
	}

	return NO;
}

- (void) parseContentLine: (NSString *)line forTag: (NSString *)aTag
{
	NSString *trimmedLine = [line trimmedString];
	BOOL isTagEnd = ([trimmedLine hasSuffix: @"</p>"] || [trimmedLine isEqualToString: @""]);

	if ([trimmedLine hasSuffix: @"</p>"])
	{
		trimmedLine = [trimmedLine substringToIndex: [trimmedLine length] - 4];
	}

	trimmedLine = [self removeBasicDocMarkupForString: trimmedLine];

	if ([trimmedLine length] > 0)
	{
		NSMutableString *desc = [self getStringFor: aTag];

		if ([desc length] > 0)
		{
			[desc appendString: @" "];
		}
		[desc appendString: trimmedLine];
	}

	if (isTagEnd)
	{
		[self endTag: aTag];
	}
}

- (void) parseMainDescriptionLine: (NSString *)line isLastLine: (BOOL)isLastLine
{
	NSMutableString *desc = [self getStringFor: @"description"];

	if (isLastLine)
	{
			[desc appendString: line];
	}
	else
	{
			[desc appendFormat: @"%@\n", line];
	}
}

- (NSArray *) validTagsBeforeMainDescription
{
	return A(@"@taskunit");
}

- (NSArray *) validTagsAfterMainDescription
{
	return A(@"@param", @"@return", @"@task");
}

- (void) reset
{
	DESTROY(currentTag);
	[parsed removeAllObjects];
}

- (void) trimSpacesAndUnclosedParagraphMarkupInMainDescription
{
	NSString *desc = [[self getStringFor: @"description"]
		stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];

	if ([desc hasSuffix: @"<p>"])
	{
		desc = [desc substringToIndex: [desc length] - 4];
		desc = [desc stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	}
	[[self getStringFor: @"description"] setString: desc];
}

/* Rough Grammar

<TASKUNIT> <DESC>  
<DESC(MAIN)>
<PARAM> <PARAMNAME> <DESC>
<RETURN> <DESC>
<TASK> <DESC>

Each line from the grammar can be wrapped in <p> and </p> pair.

If TASKUNIT or DESC(MAIN) don't end with </p>, they must end with a blank line 
such as '\n\n'.

DESC(MAIN) can contain arbitrary newlines, <tag>, </tag> and <\ tag> markup, 
unlike other grammar elements which must contain no extra markup.

TASKUNIT must be located before DESC(MAIN).

PARAM, RETURN and TASK must follow DESC(MAIN).

PARAM, RETURN and TASK declaration order doesn't matter. */
- (void) parse: (NSString *) corpus
{
	[self reset];
		
	NSMutableArray *lines = [self linesForString: corpus];
	NSArray *validTags = [self validTagsBeforeMainDescription];
	NSString *unparsedString = nil;
	BOOL isFirstLine = YES;
	BOOL wasParagraphStartOrEnd = isFirstLine;
	/* Skip first line if it is a <p> tag alone */
	int startLine = ([self isParagraphStartTag: [lines firstObject]] ? 1 : 0);

	for (int i = startLine; i < [lines count]; i++)
	{
		NSString *line = [lines objectAtIndex: i];

		/* For multiple tags are on the same line, will return a line remainder.
		   For example, <p>@param blabla @return bip</p> would be parsed up to 
		   @return and unparsedString equal to '@return bip</p>'. */		
		BOOL parsedNewTag = [self parseStartAmongTags: validTags 
		                                       atLine: line 
                                       isNewParagraph: wasParagraphStartOrEnd
		                                lineRemainder: &unparsedString];

		if (unparsedString != nil)
		{
			ETAssert(parsedNewTag);
			[lines insertObject: unparsedString atIndex: i + 1];
			unparsedString = nil;
		}
	
		if (parsedNewTag)
			continue;
	
		if (currentTag != nil)
		{
			// TODO: Move the line splitting code below elsewhere or merge it 
			// with -descriptionFromString:isTerminated:lineRemainder:.
			NSInteger nextTagIndex = [line rangeOfString: @"@"].location;
		
			if (nextTagIndex != NSNotFound)
			{
				[lines insertObject: [line substringFromIndex: nextTagIndex] 
				            atIndex: i + 1];
				line = [line substringToIndex: nextTagIndex];
			}
			[self parseContentLine: line forTag: currentTag];
		}
		else
		{
			/* When the main description is not preceded by any tags, we reinsert 
			   the start line skipped <p> */
			if (i == startLine && [self isParagraphStartTag: [lines firstObject]])
			{
				[self parseMainDescriptionLine: [lines firstObject] 
				                    isLastLine: NO];
			}
			[self parseMainDescriptionLine: line 
			                    isLastLine: (i == ([lines count] - 1))];
			validTags = [self validTagsAfterMainDescription];
		}

		wasParagraphStartOrEnd = [self isParagraphStartOrEnd: line];
	}

	[self trimSpacesAndUnclosedParagraphMarkupInMainDescription];

	/*NSLog(@"Parsed task unit: %@", [self taskUnit]);
	NSLog(@"Parsed task: %@", [self task]);
	NSLog(@"Parsed desc: %@", [self description]);
	NSLog(@"Parsed return desc: %@", [self returnDescription]);
	NSLog(@"Parsed param desc: %@", [[self getDictionaryFor: @"params"] stringValue]);*/
}

- (NSString *) description
{
	return [self getStringFor: @"description"];
}
  
- (NSString *) task
{
	return [self getStringFor: @"@task"];
}

- (NSString *) taskUnit
{
	return [self getStringFor: @"@taskunit"];
}

- (NSString *) returnDescription
{
	return [self getStringFor: @"@return"];
}

- (NSString *) descriptionForParameter: (NSString*) aName
{
	return [[self getDictionaryFor: @"params"] objectForKey: aName];
}

@end


@implementation DocMethodGroupDescriptionParser

- (void) parse: (NSString *)corpus
{
	[super parse: corpus];
	/*NSLog(@"Parsed group: %@", [self group]);
	NSLog(@"Parsed abstract: %@", [self abstract]);*/
}

- (NSArray *) validTagsBeforeMainDescription
{
	return A(@"@group", @"@abstract");
}

- (NSArray *) validTagsAfterMainDescription
{
	return [NSArray array];
}

- (NSString *) group
{
	return [self getStringFor: @"@group"];
}

- (NSString *) abstract
{
  return [self getStringFor: @"@abstract"];
}

@end



@implementation NSString (DocGenerator)

- (NSString *) trimmedString
{
	NSCharacterSet *blankCharset = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	return [self stringByTrimmingCharactersInSet: blankCharset];
}

// TODO: Should be handled in DocDescriptionParser. Would be faster too.
- (NSString *) stringByTrimmingWhitespacesAndNewlinesByLine
{
	NSCharacterSet *spaceCharset = [NSCharacterSet whitespaceCharacterSet];
	NSArray *lines = [self componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
	NSMutableArray *trimmedLines = [NSMutableArray arrayWithCapacity: [lines count]];
	BOOL skipLines = NO;

	for (NSString *line in lines)
	{
		if ([line hasPrefix: @"<example>"])
		{
			skipLines = YES;
		}
		else if ([line hasPrefix: @"</example>"])
		{
			skipLines = NO;
		}

		if (skipLines)
		{
			[trimmedLines addObject: line];
		}
		else
		{
			[trimmedLines addObject: [line stringByTrimmingCharactersInSet: spaceCharset]];
		}
	}
	return [trimmedLines componentsJoinedByString: @"\n"];
}

@end
