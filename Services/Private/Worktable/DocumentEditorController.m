/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  July 2011
	License:  Modified BSD (see COPYING)
 */

#import "DocumentEditorController.h"


@implementation DocumentEditorController

- (void) setUpMenus
{
	[[ETApp mainMenu] addItem: [ETApp documentMenuItem]];
	[[ETApp mainMenu] addItem: [ETApp insertMenuItem]];
	[[ETApp mainMenu] addItem: [ETApp arrangeMenuItem]];
}

- (void) applicationDidFinishLaunching: (NSNotification *)notif
{
	[self setUpMenus];

	ETLayoutItemFactory *itemFactory = [ETLayoutItemFactory factory];

	[[itemFactory windowGroup] setController: self];

	ETUTI *mainType = 
		[ETUTI registerTypeWithString: @"org.etoile-project.compound-document" 
		                  description: _(@"Etoile Compound or Composite Document Format")
		             supertypeStrings: A(@"public.composite-content")
		                     typeTags: [NSDictionary dictionary]];

	// TODO: Use -compoundDocumentItem
	mainItem = [itemFactory itemGroup];
	[mainItem setSize: NSMakeSize(500, 400)];
	[mainItem setLayout: [ETFreeLayout layout]];
										 
	[self setTemplate: [ETItemTemplate templateWithItem: mainItem objectClass: Nil]
	          forType: mainType];

	/* Set the type of the documented to be created by default with 'New' in the menu */
	[self setCurrentObjectType: mainType];
	
	[self newDocument: nil];
}

@end
