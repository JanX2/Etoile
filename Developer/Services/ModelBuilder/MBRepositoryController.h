/*
	Copyright (C) 2010 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  September 2010
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>
#import <EtoileUI/EtoileUI.h>

@class MBLayoutItemFactory, ETModelRepository;

@interface MBRepositoryController : ETController
{
	ETLayoutItemGroup *repositoryViewItem;
	MBLayoutItemFactory *itemFactory;
	NSUInteger nbOfUntitledRepositories;
}

@property (readonly) ETModelRepository *repository;
@property (readonly) ETModelDescriptionRepository *metaRepository;
@property (retain) ETLayoutItemGroup *repositoryViewItem;

- (IBAction) changeRepositoryPresentation: (NSPopUpButton *)sender;
- (IBAction) searchRepository: (id)sender;

- (IBAction) checkRepositoryValidity: (id)sender;
- (IBAction) showAnonymousPackageDescription: (id)sender;
- (IBAction) showPackageDescriptions: (id)sender;
- (IBAction) showEntityDescriptions: (id)sender;
- (IBAction) showPropertyDescriptions: (id)sender;
- (IBAction) showAllDescriptions: (id)sender;

@end

