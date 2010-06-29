//
//  Parameter.m
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/12/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Parameter.h"


@implementation Parameter

- (id) initWithName: (NSString*) aName andType: (NSString*) aType
{
  self = [super init];
  [self setName: aName];
  [self setType: aType];
  return self;
}

- (void) dealloc
{
  [name release];
  [type release];
  [description release];
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

- (void) setType: (NSString*) aType
{
  [aType retain];
  [type release];
  type = aType;
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
