//
//  GSDocBlock.h
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class HtmlElement;
@class DescriptionParser;

@interface GSDocBlock : NSObject 
{
  NSString* name;
  NSMutableString* rawDescription;
  NSString* filteredDescription;
}

- (void) setName: (NSString*) aName;
- (void) appendToRawDescription: (NSString*) aDescription;
- (NSString*) rawDescription;
- (HtmlElement*) htmlDescription;
- (void) addInformationFrom: (DescriptionParser*) aParser;
- (void) setFilteredDescription: (NSString*) aDescription;
- (NSString*) filteredDescription;

@end
