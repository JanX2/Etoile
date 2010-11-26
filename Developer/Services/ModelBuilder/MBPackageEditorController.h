/*
	Copyright (C) 2010 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  September 2010
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>
#import <EtoileUI/EtoileUI.h>
#import "ETModelRepository.h"

// NOTE: An exact name would be MBPackageDescriptionEditorController.
@interface MBPackageEditorController : ETController
{
	ETLayoutItemGroup *entityViewItem;
	ETLayoutItemGroup *sourceListItem;
	ETLayoutItem *viewPopUpItem;
	ETLayoutItem *modelLayerPopUpItem;
	ETEntityDescription *editedEntityDescription;
	ETModelRepository *repository;
}

@property (retain) ETLayoutItemGroup *entityViewItem;
@property (retain) ETLayoutItemGroup *sourceListItem;
@property (retain) ETLayoutItem *viewPopUpItem;
@property (retain) ETLayoutItem *modelLayerPopUpItem;
@property (retain) ETEntityDescription *editedEntityDescription;
@property (retain) ETModelRepository *repository;

- (void) updatePresentedContent;

/* Notifications */

- (void) sourceListSelectionDidChange: (NSNotification *)aNotif;

/* Actions */

- (IBAction) browseRepository: (id)sender;
- (IBAction) applyChanges: (id)sender;
- (IBAction) changePresentedModelLayer: (id)sender;
- (IBAction) changePresentedContent: (id)sender;
- (IBAction) addNewEntityDescription: (id)sender;
- (IBAction) addNewPropertyDescription: (id)sender;
- (IBAction) addNewOperation: (id)sender;
- (IBAction) addNewInstance: (id)sender;
- (IBAction) checkPackageDescriptionValidity: (id)sender;

@end


@interface MBEntityViewController : ETController
{

}

- (IBAction) changePresentedContent: (id)sender;

@end


