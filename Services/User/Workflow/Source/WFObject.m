/*
 * WFObject.m - Workflow
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 03/27/07
 * License: Modified BSD license (see file COPYING)
 */


#import "WFObject.h"


/* WFObject categories */
NSString *WFGenericCategory = @"WFGenericCategory";
NSString *WFModelCategory = @"WFModelCategory";
NSString *WFControllerCategory = @"WFControllerCategory";
NSString *WFViewCategory = @"WFViewCategory";
NSString *WFCommentCategory = @"WFCommentCategory";


@implementation WFOutput
{
	NSString *dataTypeIdentifier; /* Data-type identifier */
	NSString *identifier; /* Identifier */
	NSString *title; /* Human readable identifier */ 
}

- (id) init
{
	self = [super init];
	if (self != nil)
		{
			dataTypeIdentifier = @"workflow.datatype.nil";
			identifier = @"untitled";
			title = @"Untitled";
		}
	return self;
}

- (NSString *) dataTypeIdentifier
{
	return dataTypeIdentifier;
}

- (void) setDataTypeIdentifier: (NSString *)aString
{
	ASSIGN(dataTypeIdentifier, aString);
}

- (NSString *) identifier
{
	return identifier;
}

- (void) setIdentifier:(NSString *)aString
{
	ASSIGN(identifier, aString);
}

- (NSString *) title
{
	return title;
}

- (void) setTitle: (NSString *)aString
{
	ASSIGN(title, aString);
}

@end


@implementation WFInput
{
	WFOutput *dataSource; /* Pointer to data source */
}

- (id) init
{
	self = [super init];
	if (self != nil)
		{
			dataSource = nil; /* No default data source */
		}
	return self;
}

- (WFOutput *) dataSource
{
	return dataSource;
}

- (void) setDataSource: (WFOutput *)anOutput
{
	ASSIGN(dataSource, anOutput);
}

@end


@implementation WFObject

- (NSString *) identifier
{
	return identifier;
}

- (void) setIdentifier: (NSString *)aString
{
	ASSIGN(identifier, aString);
}

- (NSString *) title
{
	return title;
}

- (void) setTitle: (NSString *)aString
{
	ASSIGN(title, aString);
}

- (NSString *) objectCategory
{
	return objectCategory;
}

- (void) setObjectCategory: (NSString *)aCategory
{
	ASSIGN(objectCategory, aCategory);
}

- (NSPoint) position
{
	return position;
}

- (void) setPosition: (NSPoint)aPoint
{
	position = aPoint;
}

- (NSArray *) dataInputs
{
	return dataInputs;
}

- (void) setDataInputs: (NSArray *)newDataInputs
{
	ASSIGN(dataInputs, newDataInputs);
}

- (NSArray *) dataOutputs
{
	return dataOutputs;
}

- (void) setDataOutputs: (NSArray *)newDataOutputs
{
	ASSIGN(dataOutputs, newDataOutputs);
}

@end

