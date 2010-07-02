//
//  Function.h
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/8/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import "GSDocParser.h"

@class HtmlElement;

@interface DocFunction : NSObject <GSDocParserDelegate>
{
  NSString* name;
  NSMutableArray* parameters; 
  NSString* returnType;
  NSString* returnDescription;
  NSMutableString* rawDescription;
  NSString* filteredDescription;  
  NSString* task;
}

- (NSString*) task;
- (void) setTask: (NSString*) aTask;
- (void) setReturnType: (NSString*) aReturnType;
- (void) setFunctionName: (NSString*) aName;
- (NSString*) name;
- (void) addParameter: (NSString*) aName ofType: (NSString*) aType;
- (void) appendToDescription: (NSString*) aDescription;
- (NSString*) content;
- (NSString*) functionRawDescription;
- (void) setFilteredDescription: (NSString*) aDescription;
- (void) setDescription: (NSString*) aDescription forParameter: (NSString*) aName;
- (void) setReturnDescription: (NSString*) aDescription;
- (HtmlElement*) richDescription;

@end
