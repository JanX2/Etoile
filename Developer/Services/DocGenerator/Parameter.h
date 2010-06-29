//
//  Parameter.h
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/12/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Parameter : NSObject {
  NSString* name;
  NSString* type;
  NSString* description;
}

+ (id) newWithName: (NSString*) aName andType: (NSString*) aType;
- (id) initWithName: (NSString*) aName andType: (NSString*) aType;
- (void) setName: (NSString*) aName;
- (void) setType: (NSString*) aType;
- (void) setDescription: (NSString*) aDescription;
- (NSString*) name;
- (NSString*) type;
- (NSString*) description;

@end
