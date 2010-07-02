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

- (void) parse: (NSString*) corpus
{
  /*
   grammar:
   
  <DESC>
  <PARAM> <PARAMNAME> <DESC>
  <TASK> <DESC>
  <RETURN> <DESC>
  
  */
  
  BOOL param = NO;
  BOOL paramNameSet = NO;
  
  NSMutableString* current = [self getStringFor: @"description"];  

  NSArray* words = [corpus componentsSeparatedByString: @" "];
  for (int i=0; i< [words count]; i++)
  {
    NSString* word = [[words objectAtIndex: i]
                         stringByTrimmingCharactersInSet:
                         [NSCharacterSet whitespaceAndNewlineCharacterSet]];

    
    if ([word isEqualToString: @"@task"])
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
}

- (NSString*) description
{
  return [self getStringFor: @"description"];
}
  
- (NSString*) task
{
  return [self getStringFor: @"task"];
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
