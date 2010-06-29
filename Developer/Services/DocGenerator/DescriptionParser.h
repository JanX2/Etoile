//
//  DescriptionParser.h
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/12/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>

@interface DescriptionParser : NSObject 
{
  NSMutableDictionary* parsed;
}
- (id) getContent: (Class) aClass for: (NSString*) tag;
- (NSMutableString*) getStringFor: (NSString*) tag;
- (NSMutableDictionary*) getDictionaryFor: (NSString*) tag;

- (void) parse: (NSString*) corpus;

- (NSString*) description;
- (NSString*) task;
- (NSString*) returnDescription;
- (NSString*) descriptionForParameter: (NSString*) aName;

@end
