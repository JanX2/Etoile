//
//  DescriptionParser.m
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/12/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "DescriptionParser.h"


@implementation DescriptionParser

- (id) init
{
  self = [super init];
  parsed = [NSMutableDictionary new];
  return self;
}

- (void) dealloc
{
  [parsed release];
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

- (NSArray *) linesForString: (NSString *)aString
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

and where </p> is optional. */ 
- (NSString *) descriptionFromString: (NSString *)aString
{
	NSRange r = [aString rangeOfCharacterFromSet: [NSCharacterSet whitespaceCharacterSet]];
	/* Skip the first word and space e.g. @task + space */
	NSString *desc = [aString substringFromIndex: (r.location == NSNotFound ? 0 : r.location + r.length)];

	desc = [desc stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
	if ([desc hasSuffix: @"</p>"])
	{
		desc = [desc substringToIndex: [desc length] - 4];
	}
	return desc;
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
- (void) parse: (NSString*) corpus
{
	NSMutableString *current = [self getStringFor: @"description"];
	NSArray *lines = [self linesForString: corpus];
	NSCharacterSet *blankCharset = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	BOOL isParsingDocTag = NO;
	BOOL hasParsedMainDescription = NO;
	int nbOfLines = [lines count];

	for (int i = 0; i < nbOfLines; i++)
	{
		NSString *line = [lines objectAtIndex: i];
		BOOL isLastLine =  (i == (nbOfLines - 1));

		if ([line hasPrefix: @"<p>@taskunit"] || [line hasPrefix: @"@taskunit"])
		{
			current = [self getStringFor: @"taskunit"];
			[current appendFormat: @"%@ ", [self descriptionFromString: line]];

			isParsingDocTag = YES;
		}
		else if ([line hasPrefix: @"<p>@task"] || [line hasPrefix: @"@task"])
		{
			current = [self getStringFor: @"task"];
			[current appendFormat: @"%@ ", [self descriptionFromString: line]];

			isParsingDocTag = YES;
		}
		else if (isParsingDocTag == NO && hasParsedMainDescription == NO)
		{
			current = [self getStringFor: @"description"];
			[current appendFormat: @"%@\n", line]; 

			hasParsedMainDescription = YES;
		}
    		else if (isParsingDocTag)
		{
      			[current appendFormat: @"%@ ", line];
		}
		else /* Parsing Main Description */
    		{
			if (isLastLine)
			{
      				[current appendString: line];
			}
			else
			{
      				[current appendFormat: @"%@\n", line];
			}
    		}

		if (isParsingDocTag)
		{
			NSString *trimmedLine = [line stringByTrimmingCharactersInSet: blankCharset];
 			BOOL isDocTagEnd = ([trimmedLine hasSuffix: @"</p>"] || [trimmedLine isEqualToString: @""]);

			if (isDocTagEnd)
			{
				isParsingDocTag = NO;
				current = nil;
			}
		}
	}

	//NSLog(@"Parsed task unit: %@", [self taskUnit]);
	//NSLog(@"Parsed desc: %@", [self description]);
	//NSLog(@"Parsed task: %@", [self task]);

#if 0
  BOOL param = NO;
  BOOL paramNameSet = NO;
  BOOL hasParsedMainDescription = NO;  
  NSMutableString* current = [self getStringFor: @"description"];  

  NSArray* words = [corpus componentsSeparatedByString: @" "];
  for (int i=0; i< [words count]; i++)
  {
    NSString* word = [[words objectAtIndex: i]
                         stringByTrimmingCharactersInSet:
                         [NSCharacterSet whitespaceAndNewlineCharacterSet]];

	/*if ([word isEqualToString: @"<p>@taskunit"])
	{
		current = [self getStringFor: @"taskunit"];
	}
	else if (hasParsedMainDescription == NO && [word hasSuffix: @"</p>"])
	{
		current = [self getStringFor: @"description"];
		hasParsedMainDescription = YES;
	}
    else*/ if ([word isEqualToString: @"@task"])
    {
      current = [self getStringFor: @"task"];
    }
    else if ([word isEqualToString: @"@return"])
    {
      current = [self getStringFor: @"return"];
    }
    else if ([word isEqualToString: @"@param"])
    {
      param = YES;
      paramNameSet = NO;
    }
    else if (param && !paramNameSet) 
    {
      paramNameSet = YES; 
      NSMutableDictionary* params = [self getDictionaryFor: @"params"];
      current = [NSMutableString new];
      [params setObject: current forKey: word];
      [current release];
      param = paramNameSet = NO;
      //NSLog (@"PARAM NAME");
    } 
    else
    {
      [current appendFormat: @"%@ ", word];
    }
  }
#endif
}

- (NSString*) description
{
  return [self getStringFor: @"description"];
}
  
- (NSString*) task
{
  return [self getStringFor: @"task"];
}

- (NSString *) taskUnit
{
	return [self getStringFor: @"taskunit"];
}

- (NSString*) returnDescription
{
  return [self getStringFor: @"return"];
}

- (NSString*) descriptionForParameter: (NSString*) aName
{
  NSMutableDictionary* params = [self getDictionaryFor: @"params"];
  return [params objectForKey: aName];
}

@end
