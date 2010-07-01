//
//  Method.m
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Method.h"
#import "HtmlElement.h"
#import "DescriptionParser.h"

@implementation Method

- (id) init
{
  self = [super init];
  selectors = [NSMutableArray new];
  parameters = [NSMutableArray new];
  categories = [NSMutableArray new];
  rawDescription = [NSMutableString new];
  task = [[NSString alloc] initWithString: @"Default"];
  return self;
}

- (void) dealloc
{
  [selectors release];
  [parameters release];
  [categories release];
  [rawDescription release];
  [filteredDescription release];
  [task release];
  [super dealloc];
}

- (NSString*) signature
{
  NSMutableString* signature = [NSMutableString new];
  for (int i=0; i<[selectors count]; i++)
  {
    NSString* selector = [selectors objectAtIndex: i];
    [signature appendString: selector];
  }
  return [signature autorelease];
}

- (NSComparisonResult) caseInsensitiveCompare: (NSString *) aString
{
  return [aString caseInsensitiveCompare: [self signature]];
}

- (void) setReturnType: (NSString*) aReturnType
{
  [aReturnType retain];
  [returnType release];
  returnType = aReturnType;
}

- (void) setIsClassMethod: (BOOL) isTrue
{
  isClassMethod = isTrue;
}

- (BOOL) isClassMethod
{
  return isClassMethod;
}

- (void) addSelector: (NSString*) aSelector
{
  [selectors addObject: aSelector];
}

- (void) addParameter: (NSString*) aName ofType: (NSString*) aType
{
  [parameters addObject: [NSDictionary dictionaryWithObjectsAndKeys: aName, @"name", aType, @"type", nil]];
}

- (void) addCategoy: (NSString*) aCategory
{
  [categories addObject: aCategory];
}

- (void) appendToDescription: (NSString*) aDescription
{
  [rawDescription appendString: aDescription];
}

- (NSString*) methodRawDescription
{
  return rawDescription;
}

- (void) setFilteredDescription: (NSString*) aDescription
{
  [aDescription retain];
  [filteredDescription release];
  filteredDescription = aDescription;
}

- (NSString*) task
{
  return task;
}

- (void) setTask: (NSString*) aTask
{
  [aTask retain];
  [task release];
  task = aTask;
}

- (void) addInformationFrom: (DescriptionParser*) aParser
{
  [self setFilteredDescription: [aParser description]];
  /*
  for (int i=0; i<[parameters count]; i++)
  {
    Parameter* p = [parameters objectAtIndex: i];
    [p setDescription: [aParser descriptionForParameter: [p name]]];
  } 
   */
//  [self setReturnDescription: [aParser returnDescription]]; 
  [self setTask: [aParser task]];
}

/*
 <dl>
 <dt>+ (void) <strong>willVerify:</strong> (Class)aClass;</dt>
 <dd>
 
 This method will instantiate the contract and apply it
 on a class (i.e. through methods interception)
 
 </dd>
 </dl>
*/ 
- (NSString*) content
{
  H h_signature = [DIV class: @"methodSignature"];
  
  if (isClassMethod) 
  {
    [h_signature with: [DIV class: @"methodScope" with: @"+"]];
  } 
  else
  {
    [h_signature with: [DIV class: @"methodScope" with: @"-"]];
  }
  
  H h_returnType = [DIV class: @"returnType" with: @"("
                          and: [DIV class: @"type" with: returnType] and: @")"];
  
  [h_signature and: h_returnType];
  
  for (int i=0; i<[selectors count]; i++)
  {
    H h_selector = [DIV class: @"selector" with: [selectors objectAtIndex: i]];
    [h_signature and: h_selector];
    if (i<[parameters count])
    {
      NSDictionary* p = [parameters objectAtIndex: i];
      H h_parameter = [DIV class: @"parameter" with: 
                            [NSString stringWithFormat: @"(%@) ", [p objectForKey: @"type"]] 
                             //and: [DIV class: @"type" with: [p objectForKey: @"type"]] and: @") "
                             and: [DIV class: @"arg" with: [p objectForKey: @"name"]]];
//      H h_parameter = [DIV class: @"parameter" with: [NSString stringWithFormat: @"(%@)", [p objectForKey: @"type"]] 
//                             and: [DIV class: @"type" with: [p objectForKey: @"type"]] and: @") "
//                             and: [DIV class: @"arg" with: [p objectForKey: @"name"]]];
      [h_signature and: h_parameter];
    }
  }

  H methodFull = [DIV class: @"method" with: 
                  [DL with: [DT with: h_signature]
                       and: [DD with: [DIV class: @"methodDescription" with: filteredDescription]]]];
  return [methodFull content];
}

- (void) parser: (GSDocParser *)parser 
   startElement: (NSString *)elementName
  withAttributes: (NSDictionary *)attributeDict
{
		[self setReturnType: [attributeDict objectForKey: @"type"]];
		if ([[attributeDict objectForKey: @"factory"] isEqualToString: @"yes"]) 
		{
			[self setIsClassMethod: YES];
		}
}

- (void) parser: (GSDocParser *)parser
     endElement: (NSString *)elementName
    withContent: (NSString *)trimmed
{
	if ([elementName isEqualToString: @"sel"]) 
	{
		[self addSelector: trimmed];
	}
	else if ([elementName isEqualToString: @"arg"]) 
	{
		[self addParameter: trimmed 
		            ofType: [parser argTypeFromArgsAttributes: [parser currentAttributes]]];
	}
	else if ([elementName isEqualToString: @"desc"]) 
	{
		[self appendToDescription: trimmed];
	}
	else if ([elementName isEqualToString: @"method"]) /* Closing tag */
	{
		//NSLog (@"End of method <%@>, put in task <%@>", [self signature], [self task]);
		DescriptionParser *descParser = AUTORELEASE([DescriptionParser new]);

		[descParser parse: [self methodRawDescription]];
		[self addInformationFrom: descParser];

		if ([self isClassMethod])
		{
			[parser addClassMethod: self];
		}
		else
		{
			[parser addInstanceMethod: self];
		}
	}
}

@end
