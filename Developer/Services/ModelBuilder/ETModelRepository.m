/*
	Copyright (C) 2010 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  September 2010
	License:  Modified BSD  (see COPYING)
 */

#import "ETModelRepository.h"

@implementation ETModelRepository

static ETModelRepository *mainRepo = nil;

+ (id) mainRepository
{
	if (nil == mainRepo)
	{
		mainRepo = [[self alloc] initWithMetaRepository: [ETModelDescriptionRepository mainRepository]];
	}
	return mainRepo;
}

- (id) init
{
	return [self initWithMetaRepository: nil];
}

- (id) initWithMetaRepository: (ETModelDescriptionRepository *)aRepository
{
	NILARG_EXCEPTION_TEST(aRepository);
	SUPERINIT;
	_content = [[NSMutableSet alloc] init];
	ASSIGN(_metaRepository, aRepository);
	return self;
}

- (void) dealloc
{
	DESTROY(_content);
	DESTROY(_metaRepository);
}

- (id) metaRepository
{
	return _metaRepository;
}

- (void) addObject: (id)anObject
{
	[_content addObject: anObject];
}

- (void) removeObject: (id)anObject
{
	[_content removeObject: anObject];
}

- (void) containsObject: (id)anObject
{
	[_content member: anObject];
}

- (NSArray *) objects
{
	return [_content allObjects];
}

- (void) checkConstraints: (NSMutableArray *)warnings
{
	// TODO: Check the binding between classes and model descriptions.
	[_metaRepository checkConstraints: warnings];
}

- (BOOL) isOrdered
{
	return NO;
}

- (BOOL) isEmpty
{
	return ([_content count] == 0);
}

- (id) content
{
	return _content;
}

- (NSArray *) contentArray
{
	return [_content allObjects];
}

- (NSUInteger) count
{
	return [_content count];
}

- (id) objectEnumerator
{
	return [_content objectEnumerator];
}

- (void) insertObject: (id)object atIndex: (unsigned int)index
{
	[self addObject: object];
}

@end
