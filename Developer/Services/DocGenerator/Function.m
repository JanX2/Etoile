//
//  Function.m
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/8/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Function.h"
#import "HtmlElement.h"
#import "DescriptionParser.h"
#import "Parameter.h"

@implementation Function

- (id) init
{
  self = [super init];
  parameters = [NSMutableArray new];
  rawDescription = [NSMutableString new];
  task = [[NSString alloc] initWithString: @"Default"];
  return self;
}

- (void) dealloc
{
  [parameters release];
  [rawDescription release];
  [name release];
  [task release];
  [returnDescription release];
  [filteredDescription release];
  [task release];
  [returnType release];
  [super dealloc];
}

- (NSString*) name
{
  return name;
}

- (NSComparisonResult) caseInsensitiveCompare: (NSString *) aString
{
  return [aString caseInsensitiveCompare: name];
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

- (void) setReturnType: (NSString*) aReturnType
{
  [aReturnType retain];
  [returnType release];
  returnType = aReturnType;
}

- (void) setFunctionName: (NSString*) aName
{
  [aName retain];
  [name release];
  name = aName;
}

- (void) setReturnDescription: (NSString*) aDescription
{
  [aDescription retain];
  [returnDescription release];
  returnDescription = aDescription;
}

- (void) addParameter: (NSString*) aName ofType: (NSString*) aType
{
//  [parameters addObject: [NSDictionary dictionaryWithObjectsAndKeys: aName, @"name", aType, @"type", nil]];
  [parameters addObject: [Parameter newWithName: aName andType: aType]];
}

- (void) setDescription: (NSString*) aDescription forParameter: (NSString*) aName
{
  for (int i=0; i<[parameters count]; i++)
  {
    Parameter* p = [parameters objectAtIndex: i];
    if ([[p name] isEqualToString: aName])
    {
      [p setDescription: aDescription];
      return;
    }
  }
}

- (void) addInformationFrom: (DescriptionParser*) aParser
{
  [self setFilteredDescription: [aParser description]];
  for (int i=0; i<[parameters count]; i++)
  {
    Parameter* p = [parameters objectAtIndex: i];
    [p setDescription: [aParser descriptionForParameter: [p name]]];
  }    
  NSLog (@"Parser return description <%@>", [aParser returnDescription]);
  [self setReturnDescription: [aParser returnDescription]]; 
  [self setTask: [aParser task]];
}

- (void) appendToDescription: (NSString*) aDescription
{
  [rawDescription appendString: aDescription];
}

- (void) setFilteredDescription: (NSString*) aDescription
{
  [aDescription retain];
  [filteredDescription release];
  filteredDescription = aDescription;
}

- (NSString*) functionRawDescription
{
  return rawDescription;
}

- (H) richDescription
{
  H param_list = [DIV class: @"paramsList"];
  H ul = UL;
  if ([parameters count] > 0)
    [param_list and: [H3 with: @"Parameters"]];
  for (int i=0; i<[parameters count]; i++)
  {
    Parameter* p = [parameters objectAtIndex: i];
    H h_param = [LI with: [I with: [p name]]];
    [h_param and: [p description]];
    [ul and: h_param];
  }
  [param_list and: ul];
  
  if ([returnDescription length])
  {
    [param_list and: [H3 with: @"Return"]];
    [param_list and: returnDescription];
  }
  
  [param_list and: [H3 with: @"Description"]];
  [param_list and: filteredDescription];
  return param_list;
}

- (NSString*) content
{
  H h_signature = [DIV class: @"methodSignature"];
  
  H h_returnType = [DIV class: @"returnType" with: [DIV class: @"type" with: returnType]];
  
  [h_signature and: h_returnType];
  
  [h_signature and: [DIV class: @"selector" with: name]];
  [h_signature with: @"("];
  
  for (int i=0; i<[parameters count]; i++)
  {
    Parameter* p = [parameters objectAtIndex: i];
    H h_parameter = [DIV class: @"parameter" with: 
                        [DIV class: @"type" with: [p type]] 
                            and: @" " and: [DIV class: @"arg" with: [p name]]];
    if (i>0)
    {
      [h_signature and: @","];
    }
    [h_signature and: h_parameter];
  }
  [h_signature with: @")"];
  
  H methodFull = [DIV class: @"method" with: 
                  [DL with: [DT with: h_signature]
                       and: [DD with: [DIV class: @"methodDescription" with: [self richDescription]]]]];
  return [methodFull content];
}

@end
