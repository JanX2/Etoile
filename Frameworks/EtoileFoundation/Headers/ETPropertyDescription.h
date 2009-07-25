/*
 ETPropertyDescription.h
 
 A model description framework inspired by FAME 
 (http://scg.unibe.ch/wiki/projects/fame)
 
 Copyright (C) 2009 Eric Wasylishen
 
 Author:  Eric Wasylishen <ewasylishen@gmail.com>
 Date:  July 2009
 License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/ETPropertyValueCoding.h>
#import <EtoileFoundation/ETCollection.h>
#import <EtoileFoundation/ETValidationResult.h>
#import <EtoileFoundation/ETEntityDescription.h>
#import <EtoileFoundation/ETUTI.h>

@class ETEntityDescription;
@class ETRoleDescription;

/**
 * Description of an entity's property.
 *
 */
@interface ETPropertyDescription : NSObject
{
	BOOL _derived;
	BOOL _container;
	BOOL _multivalued;
	BOOL _ordered;
	NSString *_name;
	ETPropertyDescription *_opposite;
	ETEntityDescription *_owner;
	ETUTI *_UTI;
	ETRoleDescription *_role;
}
+ (id)  descriptionWithName: (NSString *)name
                      owner: (ETEntityDescription *)owner;

- (id) initWithName: (NSString *)name
              owner: (ETEntityDescription *)owner;

/* Properties */

/**
 * If YES, this property's value/values are the child/children of the entity
 * this property belongs to.
 *
 * isComposite is derived from opposite.isContainer
 */
- (BOOL) isComposite;
- (BOOL) isContainer;
- (void) setIsContainer: (BOOL)isContainer;
- (BOOL) isDerived;
- (void) setDerived: (BOOL)isDerived;
- (BOOL) isMultivalued;
- (void) setMultivalued: (BOOL)isMultivalued;
- (BOOL) isOrdered;
- (void) setOrdered: (BOOL)isOrdered;
- (NSString *) name;
- (void) setName: (NSString *)name;
- (ETPropertyDescription *) opposite;
- (void) setOpposite: (ETPropertyDescription *)opposite;
- (ETEntityDescription *) owner;
- (void) setOwner: (ETEntityDescription *)owner;
- (ETUTI *)UTI;
- (void)setUTI: (ETUTI *)UTI;

/* Validation */

- (ETRoleDescription *) role;
- (void) setRole: (ETRoleDescription *)role;

- (ETValidationResult *) validateValue: (id)value forKey: (NSString *)key;
/**
 * Pass a block which takes one argument (the value being validated)
 * and returns an ETValidationResult
 */
//- (void) setValidationBlock: (id)aBlock;

@end




/* Property Role Description classes 
 
 These allow a pluggable, more precise property description
 
 */

@interface ETRoleDescription : NSObject
{
}

- (ETPropertyDescription *) parent;
- (ETValidationResult *) validateValue: (id)value forKey: (NSString *)key;

@end

@interface ETRelationshipRole : ETRoleDescription
{
	BOOL _isMandatory;
	NSString *_deletionRule;
}

- (BOOL) isMandatory;
- (void) setMandatory: (BOOL)isMandatory;
- (NSString *) deletionRule;
- (void) setDeletionRule: (NSString *)deletionRule;

@end

@interface ETMultiOptionsRole : ETRoleDescription
{
	NSArray *_allowedOptions;
}

- (void) setAllowedOptions: (NSArray *)allowedOptions;
- (NSArray *) allowedOptions;

@end

@interface ETNumberRole : ETRoleDescription
{
	int _min;
	int _max;
}
- (int)minimum;
- (void)setMinimum: (int)min;
- (int)maximum;
- (void)setMaximum: (int)max;
@end
