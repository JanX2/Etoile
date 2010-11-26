/*
	Copyright (C) 2010 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  September 2010
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>
#import <EtoileUI/EtoileUI.h>

@class MBRepositoryController, ETModelRepository;

@interface MBLayoutItemFactory : ETLayoutItemFactory
{

}

/* UI Construction Utilities */

- (ETOutlineLayout *) outlineLayoutForBrowser;

/* Model and Metamodel Editor */

- (ETLayoutItemGroup *) editorWithPackageDescription: (ETPackageDescription *)aPackageDesc;
- (ETLayoutItemGroup *) editorTopbarWithController: (id)aController;
- (ETLayoutItemGroup *) editorBodyWithPackageDescription: (ETPackageDescription *)aPackageDesc 
                                              controller: (id)aController;
- (ETLayoutItemGroup *) sourceListWithPackageDescription: (ETPackageDescription *)aPackageDesc
                                              controller: (id)aController;
- (ETLayoutItemGroup *) entityViewWithEntityDescription: (ETEntityDescription *)anEntityDesc
                                             controller: (id)aController;

/* Model and Metamodel Browser */

- (ETLayoutItemGroup *) browserWithDescriptionCollection: (id <ETCollection>)descriptions;
- (ETLayoutItemGroup *) browserBottomBarWithController: (MBRepositoryController *)aController;
- (ETLayoutItemGroup *) browserWithRepository: (ETModelRepository *)aRepo;

/* Check Feedback */

- (ETLayoutItemGroup *) checkReportWithWarnings: (NSArray *)warnings;

@end

