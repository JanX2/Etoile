//
//  GSDocBlock.m
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "GSDocBlock.h"
#import "HtmlElement.h"


@implementation GSDocBlock

- (id) init
{
  self = [super init];
  rawDescription = [NSMutableString new];
  return self;
}

- (void) dealloc
{
  [rawDescription release];
  [name release];
  [super dealloc];
}

- (void) setName: (NSString*) aName
{
  [aName retain];
  [name release];
  name = aName;
}

- (void) appendToRawDescription: (NSString*) aDescription
{
  [rawDescription appendString: aDescription];
}

- (NSString*) rawDescription
{
  return rawDescription;
}

- (HtmlElement*) htmlDescription
{
  return [[HtmlElement new] autorelease];
}

- (NSString*) filteredDescription
{
  return filteredDescription;
}

- (void) setFilteredDescription: (NSString*) aDescription
{
  [aDescription retain];
  [filteredDescription release];
  filteredDescription = aDescription;
}

- (void) addInformationFrom: (DescriptionParser*) aParser
{
  [self setFilteredDescription: [aParser description]];
}  
@end
