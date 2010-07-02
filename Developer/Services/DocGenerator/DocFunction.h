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
#import "DocElement.h"

@class HtmlElement;

@interface DocFunction : DocElement <GSDocParserDelegate>
{
	NSMutableArray *parameters; 
	NSString *returnType;
	NSString *returnDescription; 
	NSString *task;
}

- (NSString *)task;
- (void) setTask: (NSString *)aTask;
- (void) setReturnType: (NSString *)aReturnType;
- (void) addParameter: (NSString *)aName ofType: (NSString* )aType;
- (NSString *) content;
- (void) setDescription: (NSString *)aDescription forParameter: (NSString *)aName;
- (void) setReturnDescription: (NSString *)aDescription;
- (HtmlElement *) richDescription;

@end
