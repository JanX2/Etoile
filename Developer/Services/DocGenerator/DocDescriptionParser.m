/*
	Copyright (C) 2008 Nicolas Roard

	Authors:  Nicolas Roard,
	          Quentin Mathe <quentin.mathe@gmail.com>
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

@tag + spaces + description + </p> + spaces

and where </p> is optional.

Requires the line argument to be trimmed, no white spaces at the beginning and end. */ 
- (NSString *) descriptionFromString: (NSString *)aString 
                        isTerminated: (BOOL *)isDescFinished 
                       lineRemainder: (NSString **)unparsedString
{
	NSRange r = [aString rangeOfCharacterFromSet: [NSCharacterSet whitespaceCharacterSet]];
	/* Skip the first word and space e.g. @task + space */
	NSString *desc = [aString substringFromIndex: (r.location == NSNotFound ? 0 : r.location + r.length)];

	/* Detect multiple tags on the same line, and return the next tag and its 
	   content on the current line through unparsedString */
	NSInteger nextTagIndex = [desc rangeOfString: @"@"].location;

	if (nextTagIndex != NSNotFound)
	{
		*unparsedString = [desc substringFromIndex: nextTagIndex];
		desc = [desc substringToIndex: nextTagIndex];
		*isDescFinished = YES;
	}
	else if ([desc hasSuffix: @"</p>"])
	{
		desc = [desc substringToIndex: [desc length] - 4];
		*isDescFinished = YES;
	}
	return desc;
}

- (void) parseParamRawDescription: (NSString *)rawDesc
{
	NSArray *words = [rawDesc componentsSeparatedByString: @" "];
	NSString *paramName = [words firstObject];
	NSArray *descWords = [words subarrayWithRange: NSMakeRange(1, [words count] - 1)];

	[[self getDictionaryFor: @"params"] setObject: [descWords componentsJoinedByString: @" "]
	                                       forKey: paramName];
}

/* Returns YES when a new tag has been parsed, whether or not the tag content 
has been entirely parsed. 

Requires the line argument to be trimmed, no white spaces at the beginning and end.

When multiple tags are on the same line, will parse up to the next tag e.g. 
@return, and put the line remainder into unparsedString.<br />
When a single tag is present on the line, unparsedString won't be touched.  */
- (BOOL) parseTag: (NSString *)aTag  atLine: (NSString *)line lineRemainder: (NSString **)unparsedString
{
	if (currentTag != nil)
		return NO;

	NSString *tagWithP = [NSString stringWithFormat: @"<p>%@", aTag];

	if ([line hasPrefix: tagWithP] || [line hasPrefix: aTag])
	{
		BOOL isDescFinished;
		NSString *desc = [self descriptionFromString: line 
		                                isTerminated: &isDescFinished 
		                               lineRemainder: unparsedString];

		// TODO: Remove this ugly if
		if ([aTag isEqual: @"@param"])
		{
			[self parseParamRawDescription: desc];
		}
		else
		{
			[[self getStringFor: aTag] appendFormat: @"%@ ", desc];
		}

		ASSIGN(currentTag, (isDescFinished ? nil : aTag));
		return YES;
	}

	return NO;
}

- (BOOL) parseStartAmongTags: (NSArray *)tags 
                      atLine: (NSString *)line 
               lineRemainder: (NSString **)unparsedString
{
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
	NSCharacterSet *blankCharset = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	NSString *trimmedLine = [line stringByTrimmingCharactersInSet: blankCharset];
	BOOL isTagEnd = ([trimmedLine hasSuffix: @"</p>"] || [trimmedLine isEqualToString: @""]);
	
	if ([trimmedLine hasSuffix: @"</p>"])
	{
		trimmedLine = [trimmedLine substringToIndex: [trimmedLine length] - 4];
	}
	[[self getStringFor: aTag] appendString: trimmedLine];

	ASSIGN(currentTag, (isTagEnd ? nil : aTag));
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
	return A(@"@taskunit", @"@task");
}

- (NSArray *) validTagsAfterMainDescription
{
	return A(@"@param", @"@return");
}

- (void) reset
{
	DESTROY(currentTag);
	[parsed removeAllObjects];
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

	for (int i = 0; i < [lines count]; i++)
	{
		NSString *line = [lines objectAtIndex: i];

		/* For multiple tags are on the same line, will return a line remainder.
		   For example, <p>@param blabla @return bip</p> would be parsed up to 
		   @return and unparsedString equal to '@return bip</p>'. */		
		BOOL parsedNewTag = [self parseStartAmongTags: validTags 
		                                       atLine: line 
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
			[self parseContentLine: line forTag: currentTag];
		}
		else
		{
			[self parseMainDescriptionLine: line 
			                    isLastLine: (i == ([lines count] - 1))];
			validTags = [self validTagsAfterMainDescription];
		}
	}

	//NSLog(@"Parsed task unit: %@", [self taskUnit]);
	//NSLog(@"Parsed desc: %@", [self description]);
	//NSLog(@"Parsed task: %@", [self task]);
}

- (NSString*) description
{
  return [self getStringFor: @"description"];
}
  
- (NSString*) task
{
  return [self getStringFor: @"@task"];
}

- (NSString *) taskUnit
{
	return [self getStringFor: @"@taskunit"];
}

- (NSString*) returnDescription
{
  return [self getStringFor: @"@return"];
}

- (NSString*) descriptionForParameter: (NSString*) aName
{
  NSMutableDictionary* params = [self getDictionaryFor: @"params"];
  return [params objectForKey: aName];
}

@end


@implementation DocMethodGroupDescriptionParser

- (NSArray *) validTagsBeforeMainDescription
{
	return A(@"@group");
}

- (NSArray *) validTagsAfterMainDescription
{
	return [NSArray array];
}

- (NSString *) group
{
  return [self getStringFor: @"@group"];
}

@end
