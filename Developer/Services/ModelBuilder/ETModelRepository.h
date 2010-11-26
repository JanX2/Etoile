/**	<title>ETModelRepository</title>

	<abstract>A generic object repository.</abstract>

	Copyright (C) 2010 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  September 2010
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>

/** Warning: Unstable and experimental API.

A repository to track objects to which correspond model descriptions hold 
in a meta repository.<br />
A model description repository can be used without a model repository, but the 
reverse is not true.

Each object must have a class or prototype description present in the meta 
repository. 

The repository content is not ordered.

Note: Metadescribed prototypes are not well supported yet. */
@interface ETModelRepository : NSObject <ETCollection, ETCollectionMutation>
{
	@private
	NSMutableSet *_content;
	ETModelDescriptionRepository *_metaRepository;
}

/** Returns the initial repository that exists in each process.

When this repository is created, a +[ETModelDescriptionRepository mainRepository]
is used as the meta repository. */
+ (id) mainRepository;

/** <init />
Initializes and returns a new instance repository bound to the given model 
description repository. */
- (id) initWithMetaRepository: (ETModelDescriptionRepository *)aRepository;

/** Adds the given object to the repository. */
- (void) addObject: (id)anObject;
/** Removes the given object from the repository. */
- (void) removeObject: (id)anObject;
/** Returns whether the given is present in the repository. */
- (void) containsObject: (id)anObject;
/** Returns the objects present in the repository as an array. 

The returned array contains no duplicate objects. */
- (NSArray *) objects;

/** Returns the model description repository that describes the objects in the 
repository with a metamodel. */
- (ETModelDescriptionRepository *) metaRepository;

/* Runtime Consistency Check */

/** Checks the receiver content is correctly described at the meta repository 
level and adds a short warning to the given array for each failure.

Will invoke -checkConstraints on the meta repository. */
- (void) checkConstraints: (NSMutableArray *)warnings;

@end

