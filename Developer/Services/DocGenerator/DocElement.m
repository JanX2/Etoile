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

@synthesize task, taskUnit;

- (id) init
{
	SUPERINIT;
	rawDescription = [NSMutableString new];
	task = [[NSString alloc] initWithString: @"Default"];
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

- (NSString *) description
{
	return [NSString stringWithFormat: @"%@ - %@, %@", [super description], 
		[self name], [self task]];
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

- (NSString *) HTMLDescriptionWithDocIndex: (DocIndex *)aDocIndex
{
	NSMutableString *description = [NSMutableString stringWithString: [self filteredDescription]];

	[self replaceBasicDocMarkupWithHTMLInString: description];
	[self replaceDocSectionsWithHTMLInString: description];

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
	return self;
}

- (void) dealloc
{
	[parameters release];
	[returnType release];
	[super dealloc];
}

- (void) addInformationFrom: (DescriptionParser *)aParser
{
	[super addInformationFrom: aParser];

	FOREACH(parameters, p, Parameter *)
	{
		[p setDescription: [aParser descriptionForParameter: [p name]]];
	}    
	//NSLog (@"Parser return description <%@>", [aParser returnDescription]);
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
	[parameters addObject: [Parameter newWithName: aName andType: aType]];
}

@end

