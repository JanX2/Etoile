//
//  GSDocBlock.h
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>

@class HtmlElement, DescriptionParser, DocIndex;

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

- (NSString *) insertLinksWithDocIndex: (DocIndex *)aDocIndex 
                             forString: (NSString *)aDescription;
- (NSString *) HTMLDescriptionWithDocIndex: (DocIndex *)aDocIndex;
- (HtmlElement *) HTMLRepresentation;

@end


@class Parameter;

@interface DocSubroutine : DocElement
{
	NSMutableArray *parameters;
	NSString *returnType;
	NSString *task;
}

- (NSString *) task;
- (void) setTask: (NSString *)aTask;
- (void) setReturnType: (NSString *)aReturnType;
/** Returns the return type as an anonymous parameter object to which a HTML 
representation of the type can be asked. 

When generating the HTML representation for the return type, the parameter 
object will insert symbol links and apply standard formatting (e.g. class name 
+ space + star) as expected. */ 
- (Parameter *) returnParameter;
- (void) addParameter: (NSString *)aName ofType: (NSString *)aType;

@end

