//
//  GSDocBlock.h
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>

@class HtmlElement, DescriptionParser;

@interface DocElement : NSObject 
{
	NSString *name;
	NSMutableString *rawDescription;
	NSString *filteredDescription;
}

- (NSString *) name;
- (void) setName: (NSString *)aName;

- (void) appendToRawDescription: (NSString *)aDescription;
- (NSString *) rawDescription;
- (void) setFilteredDescription: (NSString *)aDescription;
- (NSString *) filteredDescription;
- (void) addInformationFrom: (DescriptionParser *)aParser;

- (HtmlElement *) HTMLDescription;

@end


@interface DocSubroutine : DocElement
{
	NSMutableArray *parameters;
	NSString *returnType;
	NSString *task;
}

- (NSString *) task;
- (void) setTask: (NSString *)aTask;
- (void) setReturnType: (NSString *)aReturnType;
- (void) addParameter: (NSString *)aName ofType: (NSString* )aType;

@end

