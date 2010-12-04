//
//  GSDocBlock.m
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "DocElement.h"
#import "DescriptionParser.h"
#import "DocIndex.h"
#import "HtmlElement.h"
#import "Parameter.h"

@implementation DocElement

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
	[super dealloc];
}

- (id) copyWithZone: (NSZone *)aZone
{
	DocElement *copy = [[self class] allocWithZone: aZone];

	copy->rawDescription = [rawDescription mutableCopyWithZone: aZone];
	ASSIGN(copy->filteredDescription, filteredDescription);
	ASSIGN(copy->name, name);

	return copy;
}

- (NSComparisonResult) caseInsensitiveCompare: (NSString *)aString
{
	return [aString caseInsensitiveCompare: name];
}

- (NSString *) name
{
	return name;
}

- (void) setName: (NSString *)aName
{
	ASSIGN(name, aName);
}

- (void) appendToRawDescription: (NSString *)aDescription
{
	[rawDescription appendString: aDescription];
}

- (NSString *) rawDescription
{
	return rawDescription;
}

- (NSString *) filteredDescription
{
	return filteredDescription;
}

- (void) setFilteredDescription: (NSString *)aDescription
{
	ASSIGN(filteredDescription, aDescription);
}

- (void) addInformationFrom: (DescriptionParser *)aParser
{
	[self setFilteredDescription: [aParser description]];
}

- (NSMutableArray *) wordsFromString: (NSString *)aDescription
{
	/*NSScanner *scanner = [NSScanner scannerWithString: [self filteredDescription]];
	NSMutableCharacterSet *charset = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    	[charset formUnionWithCharacterSet: [NSCharacterSet punctuationCharacterSet]];
	NSString *word = nil;
	NSMutableArray *descWords = [NSMutableArray array];

	while ([scanner isAtEnd] == NO)
    {
    	BOOL foundPunctuation = [scanner scanCharactersFromSet: [NSCharacterSet punctuationCharacterSet] 
                                                    intoString: &word];
    	if (foundPunctuation == NO)
        {
    		[scanner scanUpToCharactersFromSet: charset intoString: &word];
        }
        [descWords addObject: word];
    }
	return descWords;*/

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

- (NSString *) HTMLDescriptionWithDocIndex: (DocIndex *)aDocIndex
{
	NSMutableString *description = [NSMutableString stringWithString: [self filteredDescription]];
 	NSDictionary *htmlTagSubstitutions = D(@"example>", @"pre>", @"code>", @"var>"); 
	NSUInteger length = [description length];

	for (NSString *tag in htmlTagSubstitutions)
	{
		[description replaceOccurrencesOfString: tag 
		                             withString: [htmlTagSubstitutions objectForKey: tag]
		                                options: NSCaseInsensitiveSearch
		                                  range: NSMakeRange(0, length)];
	}

	return [self insertLinksWithDocIndex: aDocIndex forString: description];
}

- (HtmlElement *) HTMLRepresentation
{
	return [[HtmlElement new] autorelease];
}

@end


@implementation DocSubroutine

- (id) init
{
	SUPERINIT;
	parameters = [NSMutableArray new];
	task = [[NSString alloc] initWithString: @"Default"];
	return self;
}

- (void) dealloc
{
	[parameters release];
	[task release];
	[task release];
	[returnType release];
	[super dealloc];
}

- (NSString *) description
{
	return [NSString stringWithFormat: @"%@ - %@, %@", [super description], 
			name, [self task]];
}

- (void) addInformationFrom: (DescriptionParser *)aParser
{
	[super addInformationFrom: aParser];

	FOREACH(parameters, p, Parameter *)
	{
		[p setDescription: [aParser descriptionForParameter: [p name]]];
	}    
	//NSLog (@"Parser return description <%@>", [aParser returnDescription]);

	[self setTask: [aParser task]];
}

- (NSString *) task
{
	return task;
}

- (void) setTask: (NSString *)aTask
{
	ASSIGN(task, aTask);
}

- (void) setReturnType: (NSString *) aReturnType
{
	ASSIGN(returnType, aReturnType);
}

- (Parameter *) returnParameter
{
	return [Parameter newWithName: nil andType: returnType];
}

- (void) addParameter: (NSString *)aName ofType: (NSString *)aType
{
	//  [parameters addObject: [NSDictionary dictionaryWithObjectsAndKeys: aName, @"name", aType, @"type", nil]];
	[parameters addObject: [Parameter newWithName: aName andType: aType]];
}

@end

