/*
	Copyright (C) 2008 Nicolas Roard

	Authors:  Nicolas Roard,
	          Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2008
	License:  Modified BSD (see COPYING)
 */

#import "DocElement.h"
#import "DocDescriptionParser.h"
#import "DocIndex.h"
#import "HtmlElement.h"
#import "DocParameter.h"

@implementation DocElement

@synthesize name, task, taskUnit, filteredDescription;

- (id) init
{
	SUPERINIT;
	rawDescription = [NSMutableString new];
	return self;
}

- (void) dealloc
{
	[rawDescription release];
	[filteredDescription release];
	[name release];
	[task release];
	[taskUnit release];
	[super dealloc];
}

- (NSString *) task
{
	if (task != nil)
	{
		return task;
	}
	else if (taskUnit != nil)
	{
		ETAssert(task == nil);
		return taskUnit;
	}
	else
	{
		return @"Default";
	}
}

- (void) setTask: (NSString *)aTask
{
	if ([aTask isEqualToString: @""])
	{
		ASSIGN(task, nil);
	}
	else
	{
		ASSIGN(task, aTask);
	}
}

- (void) setTaskUnit: (NSString *)aTask
{
	if ([aTask isEqualToString: @""])
	{
		ASSIGN(taskUnit, nil);
	}
	else
	{
		ASSIGN(taskUnit, aTask);
	}
}

- (id) copyWithZone: (NSZone *)aZone
{
	DocElement *copy = [[self class] allocWithZone: aZone];

	copy->rawDescription = [rawDescription mutableCopyWithZone: aZone];
	ASSIGN(copy->filteredDescription, filteredDescription);
	ASSIGN(copy->name, name);
	ASSIGN(copy->task, task);

	return copy;
}

- (NSComparisonResult) caseInsensitiveCompare: (NSString *)aString
{
	return [aString caseInsensitiveCompare: name];
}

- (NSString *) description
{
	return [NSString stringWithFormat: @"%@ - %@, %@", [super description], 
		[self name], [self task]];
}

+ (NSString *) forthcomingDescription
{
	return @"<em>Description forthcoming.</em>";
}

- (void) appendToRawDescription: (NSString *)aDescription
{
	[rawDescription appendString: aDescription];
}

- (NSString *) rawDescription
{
	return rawDescription;
}

- (void) addInformationFrom: (DocDescriptionParser *)aParser
{
	[self setFilteredDescription: [aParser description]];
	[self setTask: [aParser task]];
	[self setTaskUnit: [aParser taskUnit]];
}

- (NSMutableArray *) wordsFromString: (NSString *)aDescription
{
	NSCharacterSet *charset = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	return [NSMutableArray arrayWithArray: 
    	[aDescription componentsSeparatedByCharactersInSet: charset]];
}

- (NSString *) insertLinksWithDocIndex: (DocIndex *)aDocIndex forString: (NSString *)aDescription 
{
	return aDescription;
	NSMutableArray *descWords = [self wordsFromString: aDescription];
	NSCharacterSet *punctCharset = [NSCharacterSet punctuationCharacterSet];

	for (int i = 0; i < [descWords count]; i++)
	{
		NSString *word = [descWords objectAtIndex: i];
		NSUInteger length = [word length];
		NSRange r = NSMakeRange(0, length);
		BOOL usesSubword = NO;
		NSString *symbol = word;

		/* We want to trim some common punctuation patterns e.g.
		   - word
		   - (word
		   - word),
		   TODO: But we need to handle square bracket use specially. For square 
		   brackets, we detect [Class], [(Protocol)], -[Class method], 
		   +[Class method], -[(Protocol) method], +[(Protocol) method] */
		if (r.length >= 2 && [punctCharset characterIsMember: [word characterAtIndex: 0]])
		{
			r.location++;
			r.length--;
			usesSubword = YES;
		}
		if (r.length >= 2 && [punctCharset characterIsMember: [word characterAtIndex: length - 1]])
		{
			r.length--;
			if ([punctCharset characterIsMember: [word characterAtIndex: length - 2]])
			{
				r.length--;
			}
			usesSubword = YES;
		}
		if (usesSubword)
		{
			symbol = [word substringWithRange: r];
		}

		/* In most cases, no link is created and link is the same than symbol */
		NSString *link = [aDocIndex linkForSymbolName: symbol ofKind: nil];
		NSString *finalWord = link;

		if (usesSubword)
		{
			finalWord = [word stringByReplacingCharactersInRange: r withString: link];
		}

		[descWords replaceObjectAtIndex: i withObject: finalWord];
	}

	return [descWords componentsJoinedByString: @" "];
}

- (void) replaceDocSectionsWithHTMLInString: (NSMutableString *)description
{
	NSRange searchRange = NSMakeRange(0, [description length]);
	NSRange sectionTagRange = [description rangeOfString: @"@section" options: 0 range: searchRange];

	while (sectionTagRange.location != NSNotFound)	
	{
		ETAssert(sectionTagRange.length == 8);

		NSRange openingTagRange = [description rangeOfString: @"<p>" options: NSBackwardsSearch range: NSMakeRange(0, sectionTagRange.location)];
		NSRange closingTagRange = [description rangeOfString: @"</p>" options: 0 range: NSMakeRange(sectionTagRange.location, [description length] - sectionTagRange.location)];

		/* We don't replace the opening tag first, otherwise the closing tag range must be adjusted */
		[description replaceCharactersInRange: closingTagRange withString: @"</h4>"];
		[description replaceCharactersInRange: NSUnionRange(openingTagRange, sectionTagRange) withString: @"<h4>"];

		/* We don't start right after </h3> to avoid any complex range computation */
		searchRange = NSMakeRange(openingTagRange.location, [description length] - openingTagRange.location);
		sectionTagRange = [description rangeOfString: @"@section" options: 0 range: searchRange];
	}
}

- (void) replaceBasicDocMarkupWithHTMLInString: (NSMutableString *)description
{
 	NSDictionary *htmlTagSubstitutions = D(@"pre>", @"example>", @"var>", @"code>"); 

	for (NSString *tag in htmlTagSubstitutions)
	{
		[description replaceOccurrencesOfString: tag 
		                             withString: [htmlTagSubstitutions objectForKey: tag]
		                                options: NSCaseInsensitiveSearch
		                                  range: NSMakeRange(0, [description length])];
	}
}

- (NSString *) HTMLDescriptionWithDocIndex: (HTMLDocIndex *)aDocIndex
{
	NSMutableString *description = [NSMutableString stringWithString: [self filteredDescription]];

	[self replaceBasicDocMarkupWithHTMLInString: description];
	[self replaceDocSectionsWithHTMLInString: description];

	return [self insertLinksWithDocIndex: aDocIndex forString: description];
}

- (HtmlElement *) HTMLRepresentation
{
	return [HtmlElement blankElement];
}

- (NSString *) GSDocElementName
{
	return nil;
}

- (SEL) weaveSelector
{
	return NULL;
}

@end


@implementation DocSubroutine

- (id) init
{
	SUPERINIT;
	parameters = [NSMutableArray new];
	return self;
}

- (void) dealloc
{
	[parameters release];
	[returnType release];
	[super dealloc];
}

- (void) addInformationFrom: (DocDescriptionParser *)aParser
{
	[super addInformationFrom: aParser];

	FOREACH(parameters, p, DocParameter *)
	{
		[p setDescription: [aParser descriptionForParameter: [p name]]];
	}
	//NSLog (@"Parser return description <%@>", [aParser returnDescription]);
}

- (void) setReturnType: (NSString *) aReturnType
{
	ASSIGN(returnType, aReturnType);
}

- (DocParameter *) returnParameter
{
	return [DocParameter newWithName: nil andType: returnType];
}

- (void) addParameter: (DocParameter *)aParameter
{
	[parameters addObject: aParameter];
}

- (NSArray *) parameters
{
	return [NSArray arrayWithArray: parameters];
}

@end

