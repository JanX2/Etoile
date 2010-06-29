//
//  GSDocFunction.m
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "GSDocFunction.h"
#import "HtmlElement.h"

@implementation GSDocFunction

+ (id) newWithName: (NSString*) aName andReturnType: (NSString*) aType
{
  GSDocFunction* f = [GSDocFunction new];
  [f setName: aName];
  [f setReturnType: aType];
  NSLog (@"NEW FUNCTION <%@>", aName);  
  return f;
}

- (id) init
{
  self = [super init];
  parameters = [NSMutableArray new];
  return self;
}

- (void) dealloc
{
  [returnType release];
  [parameters release];
  [returnDescription release];
  [super dealloc];
}

- (void) setReturnType: (NSString*) aReturnType
{
  [aReturnType retain];
  [returnType release];
  returnType = aReturnType;
}

- (void) setReturnDescription: (NSString*) aDescription
{
  [aDescription retain];
  [returnDescription release];
  returnDescription = aDescription;
}

- (void) addParameter: (Parameter*) aParameter
{
  NSLog (@"addParameter: %@ %@", [aParameter type], [aParameter name]);
  [parameters addObject: aParameter];
}

- (void) startElement: (NSString*) anElement withAttributes: (NSDictionary*) theAttributes
{
//  NSLog (@"FUNCTION <%@> BEGIN <%@>", name, anElement);
}

- (void) endElement: (NSString*) anElement withContent: (NSString*) aContent
{
//  NSLog (@"FUNCTION <%@> END <%@>", name, anElement);
  if ([anElement isEqualToString: @"desc"])
  {
//    NSLog (@"content: <%@>", aContent);
    [self appendToRawDescription: aContent];
  }
}

- (HtmlElement*) richDescription
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

- (HtmlElement*) htmlDescription
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
                       and: [DD with: [DIV class: @"methodDescription" 
                                            with: [self richDescription]]]]];
//  NSLog (@"htmlDescription:\n%@", [methodFull content]);
  return methodFull;
}

- (void) addInformationFrom: (DescriptionParser*) aParser
{
  [super addInformationFrom: aParser];
  for (int i=0; i<[parameters count]; i++)
  {
    Parameter* p = [parameters objectAtIndex: i];
    [p setDescription: [aParser descriptionForParameter: [p name]]];
  }    
  NSLog (@"Parser return description <%@>", [aParser returnDescription]);
  [self setReturnDescription: [aParser returnDescription]]; 
//  [self setTask: [aParser task]];
}

@end
