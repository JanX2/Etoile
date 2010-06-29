//
//  GSDocFunction.h
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import "GSDocBlock.h"
#import "GSDocParser.h"

@class Parameter;
@class DescriptionParser;

@interface GSDocFunction : GSDocBlock <GSDocParserElement>{
  NSString* returnType;
  NSString* returnDescription;
  NSMutableArray* parameters;
}

+ (id) newWithName: (NSString*) aName andReturnType: (NSString*) aType;
- (void) setReturnType: (NSString*) aReturnType;
- (void) addParameter: (Parameter*) aParameter;
- (HtmlElement*) richDescription;

@end
