/*
 * WFObject.h - Workflow
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 03/27/07
 * License: Modified BSD license (see file COPYING)
 */

#import <Foundation/Foundation.h>

/* WFObject categories */
extern NSString *WFGenericCategory;
extern NSString *WFModelCategory;
extern NSString *WFControllerCategory;
extern NSString *WFViewCategory;
extern NSString *WFCommentCategory;

@interface WFOutput : NSObject
{
	NSString *dataTypeIdentifier; /* Data-type identifier */
	NSString *identifier; /* Identifier */
	NSString *title; /* Human readable identifier */ 
}

- (NSString *) dataTypeIdentifier;
- (void) setDataTypeIdentifier: (NSString *)aString;
- (NSString *) identifier;
- (void) setIdentifier: (NSString *)aString;
- (NSString *) title;
- (void) setTitle: (NSString *)aString;

@end

@interface WFInput : WFOutput
{
	WFOutput *dataSource; /* Pointer to data source */
}

- (WFOutput *) dataSource;
- (void) setDataSource: (WFOutput *)anOutput;

@end

/*
 * WFObject (Class)
 *
 * Represents an object in a WFWorkflow.
 */
@interface WFObject : NSObject
{
	NSString *identifier; /* Object identifier */
	NSString *bundleIdentifier; /* Identifier of containing bundle */
	NSString *title; /* Human readable identifier */
	NSString *objectCategory; /* The object's catagory/kind */
	NSPoint position; /* Position of object in containing WFView (if any) */
	NSArray *dataInputs; /* Array with data inputs */
	NSArray *dataOutputs; /* Array with data outputs */
}

- (NSString *) identifier;
- (void) setIdentifier: (NSString *)aString;
- (NSString *) title;
- (void) setTitle: (NSString *)aString;
- (NSString *) objectCategory;
- (void) setObjectCategory: (NSString *)aCategory;
- (NSPoint) position;
- (void) setPosition: (NSPoint)aPoint;
- (NSArray *) dataInputs;
- (void) setDataInputs: (NSArray *)newDataInputs;
- (NSArray *) dataOutputs;
- (void) setDataOutputs: (NSArray *)newDataOutputs;

@end

