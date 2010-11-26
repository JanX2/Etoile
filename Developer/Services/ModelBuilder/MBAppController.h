/*
	Copyright (C) 2010 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  September 2010
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>
#import <EtoileUI/EtoileUI.h>

@class MBLayoutItemFactory;

@interface MBAppController : ETDocumentController
{
	MBLayoutItemFactory *itemFactory;
	NSUInteger nbOfVisibleDocuments;
	NSMutableSet *openedRepositories;
}

- (IBAction) openAndBrowseRepository: (id)sender;
- (IBAction) browseMainRepository: (id)sender;

@end


@interface MBRepositoryBrowserTemplate : ETItemTemplate
{

}

@end


@interface MBPackageEditorTemplate : ETItemTemplate
{

}

@end
