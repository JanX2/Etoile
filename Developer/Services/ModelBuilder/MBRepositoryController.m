/*
	Copyright (C) 2010 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  September 2010
	License:  Modified BSD  (see COPYING)
 */

#import "MBRepositoryController.h"
#import "ETModelRepository.h"
#import "MBLayoutItemFactory.h"

@implementation MBRepositoryController

@synthesize repositoryViewItem;

- (void) dealloc
{
	DESTROY(itemFactory);
	[super dealloc];
}

- (id) init
{
	SUPERINIT;
	ASSIGN(itemFactory, [MBLayoutItemFactory factory]);
	return self;
}

- (ETModelRepository *) repository
{
	ETModelRepository *repo = [[self content] representedObject];
	ETAssert(repo != nil && [repo isKindOfClass: [ETModelRepository class]]);
	return repo;
}

- (ETModelDescriptionRepository *) metaRepository
{
	return [[self repository] metaRepository];
}

- (IBAction) changeRepositoryPresentation: (NSPopUpButton *)sender
{
	ETAssert(repositoryViewItem != nil);
	NSString *viewName = [[sender selectedItem] title];

	ETLog(@"Change repository presentation to %@", viewName);

	if ([viewName isEqual: _(@"Column")])
	{
		[repositoryViewItem setLayout: [ETBrowserLayout layout]];
		[[sender itemWithTitle: _(@"Column")] setState: NSOnState];
		[[sender itemWithTitle: _(@"List")] setState: NSOffState];
	}
	else if ([viewName isEqual: _(@"List")])
	{
		[repositoryViewItem setLayout: [itemFactory outlineLayoutForBrowser]];
		[[sender itemWithTitle: _(@"Column")] setState: NSOffState];
		[[sender itemWithTitle: _(@"List")] setState: NSOnState];
	}
	else if ([viewName isEqual: _(@"Metamodel")])
	{
		[repositoryViewItem setRepresentedObject: [self metaRepository]];
	}
	else if ([viewName isEqual: _(@"Model")])
	{
		[repositoryViewItem setRepresentedObject: [self repository]];
	}
	else
	{
		ETAssertUnreachable();
	}
	[repositoryViewItem reloadAndUpdateLayout];
}

- (IBAction) searchRepository: (id)sender
{
	ETAssert([repositoryViewItem controller] != nil);

	NSString *searchString = [sender stringValue];
	NSPredicate *predicate = nil;

	if ([searchString isEqual: @""] == NO)
	{
			predicate = [NSPredicate predicateWithFormat: @"displayName contains %@" 
			                               argumentArray: A(searchString)]; 
	}
	[[repositoryViewItem controller] setFilterPredicate: predicate];
}

- (IBAction) checkRepositoryValidity: (id)sender
{
	NSMutableArray *warnings = [NSMutableArray array];

	[[self repository] checkConstraints: warnings];
	[[itemFactory windowGroup] addItem: [itemFactory checkReportWithWarnings: warnings]];
}

- (IBAction) showAnonymousPackageDescription: (id)sender
{
	ETPackageDescription *packageDesc = [[self metaRepository] anonymousPackageDescription];
	[[itemFactory windowGroup] addObject: [itemFactory browserWithDescriptionCollection: packageDesc]];
}

- (IBAction) showPackageDescriptions: (id)sender
{
	NSArray *descriptions = [[self metaRepository] packageDescriptions];
	[[itemFactory windowGroup] addObject: [itemFactory browserWithDescriptionCollection: descriptions]];
}

- (IBAction) showEntityDescriptions: (id)sender
{
	NSArray *descriptions = [[self metaRepository] entityDescriptions];
	[[itemFactory windowGroup] addObject: [itemFactory browserWithDescriptionCollection: descriptions]];
}

- (IBAction) showPropertyDescriptions: (id)sender
{
	NSArray *descriptions = [[self metaRepository] propertyDescriptions];
	[[itemFactory windowGroup] addObject: [itemFactory browserWithDescriptionCollection: descriptions]];
}

- (IBAction) showAllDescriptions: (id)sender
{
	NSArray *descriptions = [[self metaRepository] allDescriptions];
	[[itemFactory windowGroup] addObject: [itemFactory browserWithDescriptionCollection: descriptions]];
}

@end

