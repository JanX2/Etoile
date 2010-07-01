//
//  Header.h
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/6/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import "GSDocParser.h"


@interface Header : NSObject  <GSDocParserDelegate>
{
  NSString* className;
  NSString* superClassName;
  NSString* abstract;
  NSString* overview;
  NSString* fileOverview;
  NSMutableArray* authors;
  NSString* declared;
  NSString* title;
}

- (void) setDeclaredIn: (NSString*) aFile;
- (void) setClassName: (NSString*) aName;
- (void) setSuperClassName: (NSString*) aName;
- (void) setAbstract: (NSString*) aDescription;
- (void) setOverview: (NSString*) aDescription;
- (void) setFileOverview: (NSString*) aFile;
- (void) addAuthor: (NSString*) aName;
- (void) setTitle: (NSString*) aTitle;

- (NSString*) content;

@end
