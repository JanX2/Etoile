//
//  Parameter.m
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/12/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Parameter.h"


@implementation Parameter

@synthesize typePrefix, className, protocolName, typeSuffix;

- (id) initWithName: (NSString*) aName andType: (NSString*) aType
{
	SUPERINIT;
	[self setName: aName];
	[self setType: aType];
	return self;
}

- (void) dealloc
{
  [name release];
  [type release];
  [description release];
	DESTROY(typePrefix);
    DESTROY(className);
    DESTROY(protocolName);
    DESTROY(typeSuffix);
  [super dealloc];
}

+ (id) newWithName: (NSString*) aName andType: (NSString*) aType
{
  Parameter* p = [[Parameter alloc] initWithName: aName andType: aType];
  return [p autorelease];  
}

- (void) setName: (NSString*) aName
{
  [aName retain];
  [name release];
  name = aName;
}

static inline BOOL isDelimiter(char c)
{
	return (c == ' ' || c == '*' || c == '<' || c == '>');
}

static inline unsigned int parseTypePrefix(char *rawType, unsigned int length, NSString **typePrefix)
{
	char *symbol = calloc(sizeof(char), length);;
	int i;
    BOOL foundProtocolOrClassName = NO;

	for (i = 0; i < length; i++)
    {
    	if (rawType[i] == '*')
        	break;
        
        if (rawType[i] == '<' || isupper(rawType[i]))
        {
        	foundProtocolOrClassName = YES;
        	break;
		}
    	symbol[i] = rawType[i];
    }

	if (foundProtocolOrClassName)
    {
    	[*typePrefix release];
    	*typePrefix = [[NSString alloc] initWithBytes: (const void *)symbol length: i encoding: NSUTF8StringEncoding];
		return i;
    }

	free(symbol);

	return 0;
}

static inline unsigned int parseClassOrProtocolName(char *rawType, unsigned int length, NSString **classOrProtocolName)
{
	char *symbol = calloc(sizeof(char), length);
	int i;

	for (i = 0; i < length; i++)
    {
    	if (isDelimiter(rawType[i]))
        	break;

    	symbol[i] = rawType[i];
    }

    [*classOrProtocolName release];
    *classOrProtocolName = [[NSString alloc] initWithBytes: (const void *)symbol length: i encoding: NSUTF8StringEncoding];
	free(symbol);
    return i;
}

static inline unsigned int parseTypeSuffix(char *rawType, unsigned int length, NSString **typeSuffix)
{
	char *suffix = calloc(sizeof(char), length);
	int i;

	for (i = 0; i < length; i++)
    {
    	suffix[i] = rawType[i];
    }

    [*typeSuffix release];
    *typeSuffix = [[NSString alloc] initWithBytes: (const void *)suffix length: i encoding: NSUTF8StringEncoding];
	free(suffix);

	return i;
}


/* We support parsing protocol and classe type such as:
- id<ProtocolName>
- id<ProtocolName>*
- ClassName*
- ClassName**
- ClassName<ProtocolName>*
- ClassName<ProtocolName>**

These declarations can be wrapped with a prefix and suffix too, but this isn't 
well tested yet. e.g. const.

We won't parse a protocol name that doesn't begin with a uppercase letter 
(parsing code limitation). Doesn't matter so much given we have no way to 
recognize a class name without a uppercase letter (unless we use the doc index 
to check its existence, but that would make the parsing slower without 
observable benefit since ObjC tradition requires class and protocol names to use 
camel case). */
- (void) parseType: (NSString *)aType
{
	const char *rawType = [aType UTF8String];
	unsigned int i = 0;
	BOOL isParsingProtocolName = NO;

	while (rawType[i] != '\0')
    {
    	char character = rawType[i];
		char *unparsedText = (char *)&(rawType[i]);

    	if (character == '<' || character == '>')
        {
        	/* We skip < and >. typePrefix, classOrProtocolName or typeSuffix 
               will never contain them.

               For '<' let isupper() branch parses the protocol name on next iteration.
               For '>' let else branch parses the suffix on next iteration. */
        	i++;
            isParsingProtocolName = YES;
            continue;
        }
       	else if (isupper(character))
        {
        	NSString **classOrProtocolName = (isParsingProtocolName ? &protocolName : &className);
            i += parseClassOrProtocolName(unparsedText, strlen(unparsedText), classOrProtocolName);
            isParsingProtocolName = NO;
        }
        else if (i == 0)
        {
            int advancement = parseTypePrefix(unparsedText, strlen(unparsedText), &typePrefix);
            if (advancement == 0)
                return;

            i += advancement;
        }
        else
        {
            i += parseTypeSuffix(unparsedText, strlen(unparsedText), &typeSuffix);
        }
    }
    //NSLog(@"Parsed type as prefix %@ class %@ protocol %@ suffix %@", typePrefix, className, protocolName, typeSuffix);
}

- (void) setType: (NSString*) aType
{
	ASSIGN(type, aType);
    [self parseType: aType];
}

- (void) setDescription: (NSString*) aDescription
{
  [aDescription retain];
  [description release];
  description = aDescription;
}

- (NSString*) name
{
  return name;
}

- (NSString*) type
{
  return type;
}

- (NSString*) description
{
  return description;
}

@end
