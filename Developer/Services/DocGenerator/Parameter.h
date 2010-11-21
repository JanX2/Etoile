//
//  Parameter.h
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/12/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>


@interface Parameter : NSObject {
  NSString* name;
  NSString* type;
  NSString* description;
  	NSString *typePrefix;
	NSString *className;
    NSString *protocolName;
    NSString *typeSuffix;
}

+ (id) newWithName: (NSString*) aName andType: (NSString*) aType;
- (id) initWithName: (NSString*) aName andType: (NSString*) aType;
- (void) setName: (NSString*) aName;
- (void) setType: (NSString*) aType;
- (void) setDescription: (NSString*) aDescription;
- (NSString*) name;
- (NSString*) type;
- (NSString*) description;

@property (readonly, nonatomic) NSString *typePrefix;
@property (readonly, nonatomic) NSString *className;
@property (readonly, nonatomic) NSString *protocolName;
@property (readonly, nonatomic) NSString *typeSuffix;

@end
