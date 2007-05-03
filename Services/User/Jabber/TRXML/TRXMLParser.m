//
//  TRXMLParser.m
//  Jabber
//
//  Created by David Chisnall on Wed Apr 28 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "TRXMLParser.h"
#import "TRXMLParserDelegate.h"

#define SUCCESS 0
#define FAILURE -1
#define TEMPORARYFAILURE 1

@implementation TRXMLParser
+ (id) parserWithContentHandler:(id <NSObject, TRXMLParserDelegate>) _contentHandler
{
	return [[[TRXMLParser alloc] initWithContentHandler:_contentHandler] autorelease];
}

- (id) initWithContentHandler:(id <NSObject, TRXMLParserDelegate>) _contentHandler
{
	[self init];
	[self setContentHandler:_contentHandler];
	return self;
}

- (id) init
{
	delegate = nil;
	buffer = [[NSMutableString stringWithString:@""] retain];
	openTags = [[NSMutableArray alloc] init];
	state = notag;
	return [super init];
}

- (id) setContentHandler:(id<NSObject, TRXMLParserDelegate>) _contentHandler
{
	[delegate release];
	delegate = [_contentHandler retain];
	return self;
}

- (int) parseFrom:(int)_index to:(unichar)_endCharacter
{
	int end = [buffer length];
	//TODO:  Make this a bit less slow.
	while(_index < end && [buffer characterAtIndex:_index] != _endCharacter)
	{
		_index++;
	}
	if(_index < end)
	{
		return _index;
	}
	return -1;
}

- (int) ignoreWhiteSpaceFrom:(int)_index
{
	int end = [buffer length];
	if(_index >= end)
	{
		return -1;
	}
	unichar character = [buffer characterAtIndex:_index];
	while(isspace(character))
	{
		_index++;
		if(_index >= end)
		{
			break;
		}
		character = [buffer characterAtIndex:_index];
	}
	if(_index < end)
	{
		return _index;
	}
	return -1;	
}

- (int) parseTagFrom:(int*) _index named:(NSMutableString*)_name withAttributes:(NSMutableDictionary*)_attributes
{
#define RETURN(x) (*_index) = current ; return x
#define SKIPWHITESPACE 	start = [self ignoreWhiteSpaceFrom:start]; if(start == -1) {RETURN(TEMPORARYFAILURE);} 	current = start;
#define SEARCHTO(x) current = [self parseFrom:start to:x];if(current == -1){RETURN(TEMPORARYFAILURE);}
#define CURRENTSTRING [buffer substringWithRange:NSMakeRange(start,(current - start))]

	int start = *_index;
	int current = -1;
	int bufferLength = [buffer length];
	NSString * attributeName;
	NSString * attributeValue;
	unichar currentChar;

	SKIPWHITESPACE;
	//Skip a leading '<' if there is one
	currentChar = [buffer characterAtIndex:start];
	while(
		  start < bufferLength && 
		  (
		   currentChar == '<' || 
		   currentChar == '/' 
		   )
		  )
	{
		start++;
		currentChar = [buffer characterAtIndex:start];
	}
	SKIPWHITESPACE;
/*	while([buffer characterAtIndex:start] == '<')
	{
		start++;
	}
	if([buffer characterAtIndex:start] == '/')
	{
		start++;
	}
*/	//TODO: Special case for those stupid <![CDATA[ ]]> things.
//TODO: Parse <?xml and <!DOCTYPE things with this.
	//get the name
	currentChar=[buffer characterAtIndex:current];
	while(current < (bufferLength-1) && !isspace(currentChar) && currentChar != '>' && currentChar != '/')
	{
		current++;
		currentChar=[buffer characterAtIndex:current];		
	}
	[_name setString:CURRENTSTRING];
	if([_name isEqualToString:@"!--"])
	{
		SEARCHTO('>');
		RETURN(SUCCESS);
	}
	start = current;
	//Skip to the end or the first attribute 
	SKIPWHITESPACE;
	while([buffer characterAtIndex:start] != '>' && start+1 < bufferLength && [buffer characterAtIndex:(start + 1)] != '>')
	{
		unichar quote;
		SEARCHTO('=');
		attributeName = CURRENTSTRING;
		current++;
		if((unsigned int)current >= [buffer length])
		{
			return TEMPORARYFAILURE;
		}
		quote = [buffer characterAtIndex:current];
		if(quote != '"' && quote != '\'')
		{
			RETURN(FAILURE);
		}
		current++;
		start = current;
		SEARCHTO(quote);
		attributeValue = CURRENTSTRING;
		[_attributes setValue:attributeValue forKey:attributeName];
		start = current+1;
		SKIPWHITESPACE;
	}
	if([buffer characterAtIndex:start] == '>' || (start+1 < bufferLength && [buffer characterAtIndex:(start + 1)] == '>'))
	{
		RETURN(SUCCESS);
	}
	RETURN(TEMPORARYFAILURE);
#undef RETURN
#undef CURRENTSTRING
#undef SKIPWHITESPACE
#undef SEARCHTO
}

- (BOOL) parseFromSource:(NSString*) data
{
//Macro to end parsing neatly if a particular condition is met
//Invoking this stores the unparsed buffer and returns YES.
#define ENDPARSINGIF(x) if(x) { [buffer deleteCharactersInRange:NSMakeRange(0,lastSuccessfullyParsed)]; /*NSLog(@"Unparsed: '%@'", buffer);*/return YES;}
#define SKIPTO(x) currentIndex = [self parseFrom:currentIndex to:x]; ENDPARSINGIF(currentIndex == -1);
#define CURRENTSTRING [buffer substringWithRange:NSMakeRange(lastSuccessfullyParsed,currentIndex - lastSuccessfullyParsed)]
	int currentIndex = 0;
	int lastSuccessfullyParsed = 0;
	int bufferLength;
	if(state == broken)
	{
		return NO;
	}
	
	[buffer appendString:data];
	NSLog(@"XML: %@", buffer);
	bufferLength = [buffer length];
	while(currentIndex < bufferLength)
	{
		unichar currentChar;
		//If we have not yet parsed a tag, we are looking for either:
		//1) An <?xml... tag
		//2) A <!DOCTYPE... tag
		//3) A root tag.
		//Currently, we ignore anything other than case 3.
		if(state == notag)
		{
			currentIndex = [self ignoreWhiteSpaceFrom:currentIndex];
			if(currentIndex < 0)
			{
				[buffer setString:@""];
				return YES;
			}
			SKIPTO('<');
			currentIndex++;
			state = intag;
			ENDPARSINGIF(currentIndex >= bufferLength);
			currentChar = [buffer characterAtIndex:currentIndex];
			//Case 2.
			//BUG: <?xml...?> initial tags containing the > tag will break this parser.
			if(currentChar == '!' || currentChar == '?')
			{
				//Skip to the end of the tag
				SKIPTO('>');
				state = notag;
				lastSuccessfullyParsed = currentIndex;
				currentIndex++;
			} 
			else
			{
				lastSuccessfullyParsed = currentIndex;
			}
		}
		if(state == intag)
		{
			NSMutableString * tagName = [[NSMutableString alloc] init];
			NSMutableDictionary * tagAttributes = [[NSMutableDictionary alloc] init];
			BOOL openTag = YES;
			int parseSuccess;
			
			if([buffer characterAtIndex:currentIndex] == '<')
			{
				currentIndex++;
				if(currentIndex >= bufferLength)
				{
					lastSuccessfullyParsed = currentIndex;
					return YES;
				}
			}
			if([buffer characterAtIndex:currentIndex] == '/')
			{
				openTag = NO;
				currentIndex++;
			}
			parseSuccess = [self parseTagFrom:&currentIndex named:tagName withAttributes:tagAttributes];
			switch(parseSuccess)
			{
				case SUCCESS:
					if(openTag)
					{
						if(![tagName isEqualToString:@"!--"])
						{
							NS_DURING
							{
								//NSLog(@"<%@> (%@)", tagName, openTags);
								[delegate startElement:tagName attributes:tagAttributes];
							}
							NS_HANDLER
							{
								NSLog(@"An exception occured while starting element %@.  Write better code!  Exception: %@", tagName, [localException reason]);	
							}
							NS_ENDHANDLER
							[openTags addObject:tagName];
							state = incdata;
						}
					}
					currentChar = [buffer characterAtIndex:currentIndex];
					if(currentChar == '/' || !openTag)
					{
						if([openTags count] == 0 || ![[openTags lastObject] isEqualToString:tagName])
						{
							state = broken;
							NSLog(@"Tag %@ closed, but last tag opened was %@.", tagName, [openTags lastObject]);
							return NO;
						}
						[openTags removeLastObject];
						NS_DURING
						{
							//NSLog(@"</%@> (%@)", tagName, openTags);
							[delegate endElement:tagName];
						}
						NS_HANDLER
						{
							NSLog(@"An exception (%@) occured while ending element %@.  Write better code!", [localException reason], tagName);
						}
						NS_ENDHANDLER
						currentIndex++;
						state = notag;
					}
					currentIndex--;
					SKIPTO('>');
					currentIndex++;
					lastSuccessfullyParsed = currentIndex;
					break;
				case TEMPORARYFAILURE:
					ENDPARSINGIF(YES);
				case FAILURE:
					state = broken;
					return NO;
				default:
					NSLog(@"parseTagFrom returned %d, which is just plain wrgon.", parseSuccess);
					state = broken;
					return NO;
			}
			[tagName release];
			[tagAttributes release];
		}
		else if(state == incdata)
		{
			NSString * cdata;
			SKIPTO('<');
			if(currentIndex != lastSuccessfullyParsed)
			{
				cdata = CURRENTSTRING;
				//If cdata contains a > (close tag) then we are parsing nonsense, not XML.
				if([cdata rangeOfString:@">"].location != NSNotFound)
				{
					[cdata release];
					state = broken;
					return NO;
				}
				NS_DURING
				{
					[delegate characters:cdata];
				}
				NS_HANDLER
				{
					NSLog(@"An exception occured while adding CDATA: \n'%@'\n.  Write better code!", cdata);
				}
				NS_ENDHANDLER
				lastSuccessfullyParsed = currentIndex;
			}
			state = intag;
		}
	}
	[buffer setString:@""];
	return YES;
#undef CURRENTSTRING
#undef ENDPARSINGIF
#undef SKIPTO
}

@end
