//
//  Header.m
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/6/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Header.h"
#import "HtmlElement.h"

@implementation Header

- (id) init
{
  self = [super init];
  authors = [NSMutableArray new];
  return self;
}

- (void) dealloc
{
  [authors release];
  [className release];
  [superClassName release];
  [abstract release];
  [overview release];
  [title release];
  [super dealloc];
}

- (void) setDeclaredIn: (NSString*) aFile
{
  [aFile retain];
  [declared release];
  declared = aFile;
}

- (void) setClassName: (NSString*) aName
{
  [aName retain];
  [className release];
  className = aName;
}

- (void) setSuperClassName: (NSString*) aName 
{
  [aName retain];
  [superClassName release];
  superClassName = aName;
}

- (void) setAbstract: (NSString*) aDescription
{
  [aDescription retain];
  [abstract release];
  abstract = aDescription;
}

- (void) setOverview: (NSString*) aDescription
{
  [aDescription retain];
  [overview release];
  overview = aDescription;
}

- (void) setFileOverview: (NSString*) aFile
{
  [aFile retain];
  [fileOverview release];
  fileOverview = aFile;
}

- (void) addAuthor: (NSString*) aName
{
  if (aName != nil)
    [authors addObject: aName];
}

- (void) setTitle: (NSString*) aTitle
{
  [aTitle retain];
  [title release];
  title = aTitle;
}

- (NSString*) content
{
  H h_title = [DIV id: @"classname"];
  if (title)
  {
    [h_title with: [H2 with: title]];
  }
  if (className)
  {
    [h_title with: className and: @" : " and: superClassName];
  }
  
  H tdAuthors = TD;
  for (int i=0; i<[authors count]; i++)
  {
    [tdAuthors with: [authors objectAtIndex: i] and: @" "];
  }
  H table = [TABLE with: [TR with: [TH with: @"Authors"] and: tdAuthors]
                               and: [TR with: [TH with: @"Declared in:"] and: [TD with: declared]]];
  H meta = [DIV id: @"meta" with: [P id: @"metadesc" with: abstract] and: table];
  H h_overview = [DIV id: @"overview" with: [H3 with: @"Overview"]];
  BOOL setOverview = NO;
  if (fileOverview != nil)
  {
    NSString* fo = [NSString stringWithContentsOfFile: fileOverview];
    [h_overview and: fo];
    setOverview = YES;
  }
  else if (overview != nil)
  {
    [h_overview and: [P with: overview]];
    setOverview = YES;
  }
  H header = [DIV id: @"header" with: h_title and: meta];
  if (setOverview) [header and: h_overview];
  return [NSString stringWithFormat: @"%@", [header content]];
}

@end
